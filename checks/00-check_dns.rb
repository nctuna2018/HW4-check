require 'dmarc'

class Checker
	module CheckDns
		DESPF = File.join(__dir__, 'spf-tools', 'despf.sh')

		def check_a
			record = Resolver.query("mail.#{@base_domain}")
			pass!(:Aa) unless record.empty?

			@mail_host = record.first
		rescue
		end

		def check_mx
			record = Resolver.query(@base_domain, :MX)
			pass!(:Ab) if record.first == "mail.#{@base_domain}."
		rescue
		end

		def check_spf_txt
			spf = `#{DESPF} #{@base_domain}`.strip!
			txt = `#{DESPF} -x #{@base_domain}`.strip!

			spf_expect = "-all\nip4:#{@mail_host}"
			txt_expect = "-all\nip4:#{@mail_host}"

			pass!(:Ac) if spf == spf_expect && txt == txt_expect
		rescue
		end

		def check_dmarc
			result = ::DMARC::Record.query(@base_domain)

			pass!(:Ad) if result.v == :DMARC1 && result.p == :reject
		rescue
		end

		def check!
			super

			check_a
			check_mx
			check_spf_txt
			check_dmarc
		end
	end
end
