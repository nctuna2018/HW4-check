class Checker
	module CheckIngoingFilter
		EICAR = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'

		def check_spam
			smtp do |s|
				s.sendmail("Subject: test Fa\n\n#{EICAR}\n", "TA@tzute.nasa", "TA@#{@base_domain}")
			end

			imap('TA', @private_key) do |i|
				i.select('INBOX')
				status = i.status('INBOX', %w(UNSEEN MESSAGES))
				return if status.fetch('UNSEEN', 0) == 0
				last = status.fetch('MESSAGES', 0)
				return if last == 0

				begin
					data = i.fetch(last, "BODY[HEADER.FIELDS (SUBJECT)]")&.first
					return if data.nil?
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip!.tr(' ', '') == 'Subject:***SPAM***testFa'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			pass!(:Fa)
		rescue
		end

		def check_spf_dkim_dmarc
			`echo "Subject: test Fb1" | sendmail -f "TA@reject.tzute.nasa" -r "TA@reject.tzute.nasa" "TA@#{@base_domain}"`
			`echo "Subject: test Fb2" | sendmail -f "TA@none.tzute.nasa" -r "TA@none.tzute.nasa" "TA2@#{@base_domain}"`

			sleep(40)

			imap('TA', @private_key) do |i|
				i.select('INBOX')
				status = i.status('INBOX', %w(UNSEEN MESSAGES))
				break if status.fetch('UNSEEN', 0) == 0

				last = status.fetch('MESSAGES', 0)
				break if last == 0

				begin
					data = i.fetch(last, "BODY[HEADER.FIELDS (SUBJECT)]")&.first
					return if data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Fb1'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			imap('TA2', @private_key) do |i|
				i.select('INBOX')
				status = i.status('INBOX', %w(UNSEEN MESSAGES))
				return if status.fetch('UNSEEN', 0) == 0
				last = status.fetch('MESSAGES', 0)
				return if last == 0

				begin
					data = i.fetch(last, "BODY[HEADER.FIELDS (SUBJECT)]")&.first
					return if data.nil?
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Fb2'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			pass!(:Fb)
		rescue
		end

		def check!
			super

			check_spam
			check_spf_dkim_dmarc
		end
	end
end

