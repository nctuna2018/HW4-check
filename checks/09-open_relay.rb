class Checker
	module CheckOpenRelay
		def check_open_relay
			smtp do |s|
				s.sendmail("Subject: test J", "other@tzute.nasa", "another@mail.tzute.nasa")
			rescue Net::SMTPError => e 
				pass!(:J)
			end
		rescue
		end

		def check!
			super

			check_open_relay
		end
	end
end
