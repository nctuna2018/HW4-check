class Checker
	module CheckAlias
		def check_ta3
			smtp('TA', @private_key) do |s|
				s.sendmail("Subject: test Ea\n\nEa\n", "TA@#{@base_domain}", "TA3@#{@base_domain}")
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
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Ea'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			pass!(:Ea)
		rescue
		end

		def check_pipe_alias
			smtp('TA', @private_key) do |s|
				s.sendmail("Subject: test Eb1\n\nEb1\n", "TA@#{@base_domain}", "i-am-a|TA@#{@base_domain}")
				s.sendmail("Subject: test Eb2\n\nEb2\n", "TA@#{@base_domain}", "kind-of-random-string|TA2@#{@base_domain}")
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
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Eb1'
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
					return unless data.attr.fetch('BODY[HEADER.FIELDS (SUBJECT)]', '').strip! == 'Subject: test Eb2'
				ensure
					i.store(last, "+FLAGS", [:Deleted])
				end
			end

			pass!(:Eb)
		rescue
		end

		def check!
			super

			check_ta3
			check_pipe_alias
		end
	end
end
