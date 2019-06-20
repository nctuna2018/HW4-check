class Checker
	module CheckGreylist
		def check_greylist
			smtp do |s|
				s.sendmail("Subject: test D\n\nD\n", "TA@tzute.nasa", "TA@#{@base_domain}")
				raise
			rescue Net::SMTPError => e
				raise unless e.message[/greylist|postgrey|450 4\.2\.0|451 4\.7\.1/i]
			end

			sleep(40)

			smtp do |s|
				s.sendmail("Subject: test D\n\nD\n", "TA@tzute.nasa", "TA@#{@base_domain}")
			end

			imap('TA', @private_key) do |i|
				i.select('INBOX')
				status = i.status('INBOX', %w(UNSEEN MESSAGES))
				return if status.fetch('UNSEEN', 0) == 0
				last = status.fetch('MESSAGES', 0)
				return if last == 0
				i.store(last, "+FLAGS", [:Deleted])
			end

			pass!(:D)
		rescue
		end

		def check!
			super

			check_greylist
		end
	end
end
