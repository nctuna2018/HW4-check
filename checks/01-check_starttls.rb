require 'timeout'
require 'net/imap'
require 'net/smtp'

class Checker
	module CheckStarttls
		CHECK_ALIVE = 5

		TLS_VERISONS = {
			:TLSv1_3 => '',
			:TLSv1_2 => '-tls1_2',
			:TLSv1_1 => '-tls1_1',
		}

		def check_imap_tls
			@imap_tls_version = TLS_VERISONS.select do |v, flag|
				Timeout::timeout(CHECK_ALIVE) do
					result = `echo Q | openssl s_client -connect mail.#{@base_domain}:imap -starttls imap -crlf #{flag} 2>/dev/null`
					/Secure Renegotiation IS supported/.match result
				end
			rescue
				false
			end.keys.first

			pass!(:Ba) unless @imap_tls_version.nil?
		rescue
		end

		def check_smtp_tls
			@smtp_tls_version = TLS_VERISONS.select do |v, flag|
				Timeout::timeout(CHECK_ALIVE) do
					result = `echo Q | openssl s_client -connect mail.#{@base_domain}:smtp -starttls smtp -crlf #{flag} 2>/dev/null`
					/Secure Renegotiation IS supported/.match result
				end
			rescue
				false
			end.keys.first

			pass!(:Bb) unless @smtp_tls_version.nil?
		rescue
		end

		def check!
			super

			check_imap_tls
			check_smtp_tls
		end

		private

		def imap(user, password)
			Net::IMAP.new("mail.#{@base_domain}").tap do |imap|
				imap.starttls({ ssl_version: @imap_tls_version, verify_mode: OpenSSL::SSL::VERIFY_NONE }, false)
			  imap.login(user, password)

				yield imap if block_given?
			end
		end

		def smtp(user = nil, password = nil)
			smtp_tls_context = OpenSSL::SSL::SSLContext.new(@smtp_tls_version)
			smtp_tls_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
			Net::SMTP.new("mail.#{@base_domain}").tap do |smtp|
				smtp.enable_starttls(smtp_tls_context)
				smtp.start('mail.tzute.nasa', user, password, user.nil? ? nil : :login) do |s|
					yield s if block_given?
				end
			end
		end
	end
end
