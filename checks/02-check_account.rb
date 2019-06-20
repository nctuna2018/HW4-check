class Checker
	module CheckAccount
		def check_login_ta
			imap('TA', @private_key)
			smtp('TA', @private_key)

			pass!(:Ca)
		rescue
		end

		def check_login_ta2
			imap('TA2', @private_key)
			smtp('TA2', @private_key)

			pass!(:Cb)
		rescue
		end

		def check_mails
			smtp('TA', @private_key) do |s|
				s.sendmail("Subject: test Cca\n\nCca\n", "TA@#{@base_domain}", "TA@#{@base_domain}")
				s.sendmail("Subject: test Ccb\n\nCcb\n", "TA@#{@base_domain}", "TA2@mail.#{@base_domain}")
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
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Cca'
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
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Ccb'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			pass!(:Cc)
		rescue
		end

		def check!
			super

			check_login_ta
			check_login_ta2
			check_mails
		end
	end
end
