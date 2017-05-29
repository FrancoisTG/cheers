class HangoutMailer < ApplicationMailer

  def creation_confirmation(hangout_id)
    @hangout = Hangout.find(hangout_id)
    @user = hangout.user
    mail(
      to:       @hangout.user.email,
      subject: default_i18n_subject(hangout_title: @hangout.title)
    )
  end

  def update_confirmation(hangout_id)
    @hangout = Hangout.find(hangout_id)
    @user = hangout.user
    mail(
      to:       @hangout.user.email,
      subject: default_i18n_subject(hangout_title: @hangout.title)
    )
  end

  def vote_starting(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @guest = @confirmation.user
    @owner = @hangout.user
      mail(
        to:       @guest.email,
        subject:  default_i18n_subject(hangout_title: @hangout.title)
      )
  end

  def hangout_update(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @guest = @confirmation.user
    @owner = @hangout.user

      mail(
        to:       @guest.email,
        subject:  default_i18n_subject(host_name: @owner.first_name, hangout_title: @hangout.title)
      )
  end

  def cancelled(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @guest = @confirmation.user
    @owner = @hangout.user

      mail(
        to:       @guest.email,
        subject:  default_i18n_subject(hangout_title: @hangout.title)
      )
  end

  def result(confirmation_id)
    @confirmation = Confirmation.find(confirmation_id)
    @hangout = @confirmation.hangout
    @place = @hangout.place
    @guest = @confirmation.user
    @owner = @hangout.user

      mail(
        to:       @guest.email,
        subject:  default_i18n_subject(hangout_title: @hangout.title)
      )
  end


end
