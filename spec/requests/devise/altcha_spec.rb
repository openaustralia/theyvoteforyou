# frozen_string_literal: true

require "spec_helper"

# The ALTCHA wiring across all four anonymous forms. The proof-of-work itself is covered in
# spec/lib/altcha_challenge_spec.rb; this is about the flags, the rejection, and what a person is
# left looking at.
#
# These assert on the rejection message rather than on the response status, because three of the
# four forms already answer 422 for their own validation failures and the two would be
# indistinguishable.
describe "ALTCHA on the anonymous forms", type: :request do
  # Deliberately fictional. Never put a real person's details in test data.
  # let! rather than let, so the account exists before an example starts counting rows. Built
  # lazily it would be created inside an `expect { }` block and look like the form's own doing.
  let!(:existing) { create(:confirmed_user, email: "voter@example.org", password: "correct horse battery") }
  let(:rejection) { "needs JavaScript turned on" }

  def forms
    {
      "sign up" => {
        new_path: "/users/sign_up", path: "/users", scope: "registrations",
        params: { user: { email: "newcomer@example.org", name: "Pat Placeholder",
                          password: "correct horse battery" } }
      },
      "log in" => {
        new_path: "/users/sign_in", path: "/users/sign_in", scope: "sessions",
        params: { user: { email: existing.email, password: "correct horse battery" } }
      },
      "password reset" => {
        new_path: "/users/password/new", path: "/users/password", scope: "passwords",
        params: { user: { email: existing.email } }
      },
      "resend confirmation" => {
        new_path: "/users/confirmation/new", path: "/users/confirmation", scope: "confirmations",
        params: { user: { email: existing.email } }
      }
    }
  end

  # The sign-up form also carries invisible_captcha's spinner, which is seeded into the session
  # when the form is fetched. A real person always fetches the form first, so do the same rather
  # than posting cold, which invisible_captcha correctly treats as spam.
  def spinner_from(new_path)
    get new_path
    response.body[/name="spinner" value="([^"]+)"/, 1]
  end

  def submit(form, extra = {})
    spinner = spinner_from(form[:new_path])
    post form[:path], params: form[:params].merge(extra).merge(spinner: spinner).compact
  end

  def solved_payload(scope)
    challenge = AltchaChallenge.issue(scope: scope)
    Base64.strict_encode64(
      Altcha::V2::Payload.new(
        challenge: challenge, solution: Altcha::V2.solve_challenge(challenge)
      ).to_json
    )
  end

  ["sign up", "log in", "password reset", "resend confirmation"].each do |name|
    describe "the #{name} form" do
      let(:form) { forms.fetch(name) }

      context "with both flags off" do
        it "does not show the widget" do
          get form[:new_path]
          expect(response.body).not_to include "altcha"
        end

        it "accepts a submission with no answer" do
          submit(form)
          expect(response.body).not_to include rejection
        end
      end

      context "with :altcha on but :altcha_enforce off" do
        before { Flipper.enable(:altcha) }

        it "shows the widget" do
          get form[:new_path]
          expect(response.body).to include "altcha-widget"
        end

        it "loads the widget script" do
          get form[:new_path]
          expect(response.body).to match(%r{<script src="/assets/altcha[-.]})
        end

        it "still accepts a submission with no answer, because monitor mode blocks nothing" do
          submit(form)
          expect(response.body).not_to include rejection
        end
      end

      context "with both flags on" do
        before do
          Flipper.enable(:altcha)
          Flipper.enable(:altcha_enforce)
        end

        it "rejects a submission with no answer, and says why" do
          submit(form)
          expect(response.body).to include rejection
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "keeps the email address they typed" do
          submit(form)
          expect(response.body).to include form[:params][:user][:email]
        end

        it "offers a fresh challenge, so the retry works" do
          submit(form)
          expect(response.body).to include "altcha-widget"
        end

        it "accepts a submission with a correct answer" do
          submit(form, altcha: solved_payload(form[:scope]))
          expect(response.body).not_to include rejection
        end

        it "rejects an answer solved for a different form" do
          other = form[:scope] == "passwords" ? "registrations" : "passwords"
          submit(form, altcha: solved_payload(other))
          expect(response.body).to include rejection
        end

        it "rejects a made up answer" do
          submit(form, altcha: "not a real answer")
          expect(response.body).to include rejection
        end
      end

      # Turning :altcha off has to be a complete rollback. If enforcement outlived it, all four
      # forms would reject everybody with no widget on the page to satisfy them.
      context "with :altcha_enforce on but :altcha off" do
        before { Flipper.enable(:altcha_enforce) }

        it "accepts a submission with no answer" do
          submit(form)
          expect(response.body).not_to include rejection
        end
      end
    end
  end

  describe "the sign up form specifically" do
    let(:form) { forms.fetch("sign up") }

    before do
      Flipper.enable(:altcha)
      Flipper.enable(:altcha_enforce)
    end

    it "keeps the username as well as the email" do
      submit(form)
      expect(response.body).to include "Pat Placeholder"
    end

    it "creates no account when the check fails" do
      expect { submit(form) }.not_to change(User, :count)
    end

    it "creates an account when the check passes" do
      expect do
        submit(form, altcha: solved_payload("registrations"))
      end.to change(User, :count).by(1)
    end
  end
end
