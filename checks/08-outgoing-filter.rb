class Checker
	module CheckOutgoingFilter
		def check_outgoing_filter
			smtp('TA', @private_key) do |s|
				s.sendmail("Subject: =?UTF-8?B?5bCP54aK57at5bC8?=", "TA@#{@base_domain}", "bear@mail.tzute.nasa")
			rescue Net::SMTPError => e 
				pass!(:I)
			end
		rescue
		end

		def check!
			super

			check_outgoing_filter
		end
	end
end
