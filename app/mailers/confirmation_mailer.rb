class ConfirmationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.confirmation_mailer.guest_confirmed.subject
  #
  def guest_confirmed(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @guest = @confirmation.user
    @owner = @hangout.user

      mail(
        to:       @owner.email,
        subject:  default_i18n_subject(guest_name: @guest.first_name, hangout_title: @hangout.title)
      )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.confirmation_mailer.guest_cancelled.subject
  #
  def guest_cancelled(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @guest = @confirmation.user
    @owner = @hangout.user

      mail(
        to:       @owner.email,
        subject:  default_i18n_subject(guest_name: @guest.first_name, hangout_title: @hangout.title)
      )
  end

end
