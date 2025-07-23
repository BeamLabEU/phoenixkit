defmodule PhoenixKit.Mailer do
  @moduledoc """
  Mailer module for PhoenixKit authentication emails.
  
  This module handles sending authentication-related emails such as
  confirmation emails, password reset emails, etc.
  """
  
  use Swoosh.Mailer, otp_app: :phoenix_kit
end