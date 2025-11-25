class TestMailer < ApplicationMailer
  def test_email(recipient_email)
    @recipient_email = recipient_email
    @test_time = Time.current
    @environment = Rails.env
    
    mail(
      to: recipient_email,
      subject: "[OutcomeTracker] Test Email - #{Rails.env.capitalize}"
    )
  end
end