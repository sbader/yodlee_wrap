require "yodlee_wrap"

describe 'the yodlee api client integration tests', integration: true do
  let(:config) {
    {
      cobranded_username: ENV['YODLEE_COBRANDED_USERNAME'],
      cobranded_password: ENV['YODLEE_COBRANDED_PASSWORD'],
    }
  }

  let(:api) { YodleeWrap::YodleeApi.new(config) }

  let(:registered_user) {
    {
      username: 'sbMemstudentloangenius1',
      password: 'sbMemstudentloangenius1#123'
    }
  }

  describe 'the yodlee apis cobranded login endpoint' do
    context 'Given valid cobranded credentials and base_url' do
      context 'When /authenticate/coblogin is called the return' do
        subject { api.cobranded_login }

        it { is_expected.to be_kind_of(YodleeWrap::Response) }
        it { is_expected.to be_success }

        it 'contains valid json response' do
          expect(subject.body['session']).not_to be_nil
          expect(subject.body['session']['cobSession']).not_to be_nil
          expect(subject.status).to eq 200
        end

        it 'sets the cobrand_auth variable' do
          expect(api.cobranded_auth).to be_nil
          subject
          expect(api.cobranded_auth).not_to be_nil
        end
      end
    end
  end

  describe 'the yodlee apis user login endpoint' do
    context 'Given valid cobranded credentials' do
      context 'Given a new user who does not exist within the cobranded account' do
        describe 'When login_user is called the return' do
          subject {
            api.cobranded_login
            api.login_user(username: 'testuser', password: 'testpassword')
          }

          it { is_expected.to be_kind_of(YodleeWrap::Response) }
          it { is_expected.to be_fail }

          it 'returns an error response' do
            expect(subject.error_code).not_to be_empty
            expect(subject.error_message).not_to be_empty
            expect(subject.body['errorCode']).to eq 'Y002'
            expect(subject.body['errorMessage']).to eq 'Invalid loginName/password'
            expect(subject.status).to eq 401
          end

          it 'does not set the user auth variable' do
            expect(api.user_auth).to be_nil
            subject
            expect(api.user_auth).to be_nil
          end
        end
      end

      context 'Given a user who does exist within the cobranded account' do
        describe 'When login_user is called the return' do
          subject {
            api.cobranded_login
            api.login_user(registered_user)
          }

          it { is_expected.to be_a(YodleeWrap::Response) }
          it { is_expected.to be_success }

          it 'returns an response including user and session information' do
            expect(subject.body).to have_key('user')
            expect(subject.body['user']).to have_key('session')
            expect(subject.status).to eq 200
          end

          it 'sets the user_auth variable' do
            expect(api.user_auth).to be_nil
            subject
            expect(api.user_auth).not_to be_nil
          end
        end
      end
    end
  end

  describe 'the yodlee apis register user endpoint' do
    context 'Given a valid cobranded credentials' do
      context 'Given a new user who does not exist within the cobranded account' do
        context 'When register_user endpoint is called the response' do
          context 'with invalid password' do
            subject {
              api.cobranded_login
              test_user = "testuser#{rand(100...200)}@gmail.com"
              api.register_user(username: test_user, password: 'testpassword143', email: test_user, subscribe: false)
            }

            after {
              api.unregister_user
            }

            it 'is expected to have an error response' do
              is_expected.to be_a(YodleeWrap::Response)
              is_expected.to be_fail
              expect(subject.error_message).to eq "Your password doesn't meet required criteria"
              expect(subject.status).to eq 400
              expect(api.user_session_token).to be_nil
            end
          end

          # Testing user creation is limited in sandbox environment.
          context 'with valid password' do
            subject {
              api.cobranded_login
              test_user = "testuser#{rand(100...200)}"
              api.register_user(username: "#{test_user}", password: 'Testpassword#143', email: "#{test_user}@example.com", subscribe: false)
            }

            after {
              api.unregister_user
            }

            it 'is expected to give accessibility error because yodlee sandbox limitations' do
              is_expected.to be_a(YodleeWrap::Response)
              is_expected.to be_fail
              expect(subject.error_message).to eq 'Accessibility denied.'
              expect(subject.status).to eq 400
            end
          end
        end
      end
    end
  end

  # Testing user creation/deletion is limited in sandbox environment
  # describe '#unregister_user' do
  #   context 'Given a valid cobranded credentials and base_url' do
  #     context 'Given a user who it logged into the api' do
  #       context 'When #unregister_user is called the response' do
  #         subject {
  #           api.cobranded_login
  #           api.login_or_register_user "testuser#{rand(100...200)}", 'testpassword143', 'test@test.com'
  #           expect(api.user_session_token).not_to be_nil
  #           api.unregister_user
  #         }
  #
  #
  #         it 'is expected to offer a valid response' do
  #           is_expected.to be_kind_of(YodleeWrap::Response)
  #           is_expected.to be_success
  #           expect(api.user_session_token).to be_nil
  #         end
  #
  #         after { api.unregister_user }
  #
  #       end
  #     end
  #   end
  # end

  describe 'the yodlee_wrap login_or_register_user method' do
    before { api.cobranded_login }

    context 'Given a new user with valid credentials' do
      after { api.unregister_user }
      let(:email) { "testuser#{rand(100...200)}@test.com" }
      let(:password) { "Password##{rand(100...200)}" }

      context 'When login_or_register_user is called' do
        subject { api.login_or_register_user(username: email, password: password, email: email) }

        it 'should give an accessibility denied error because yodlee sandbox limitations'  do
          expect(subject).to be_fail
          expect(subject).to be_a(YodleeWrap::Response)
          expect(subject.error_message).to eq('Accessibility denied.')
        end
      end
    end

    context 'Given an existing user with valid credentials' do

      context 'When login_or_register_user is called' do
        subject { api.login_or_register_user(username: registered_user[:username], email: registered_user[:username], password: registered_user[:password]) }

        it 'should login the user and not register them' do
          expect(subject).to be_success
          expect(subject).to be_a(YodleeWrap::Response)
          expect(api.user_session_token).not_to be_nil
        end
      end
    end

    context 'given an existing user with invalid password' do
      context 'when login_or_register_user is called' do
        subject { api.login_or_register_user(username: registered_user[:username], email: registered_user[:username], password: 'WRONGPASSWORD') }

        it 'will attempt to create a new user' do
          expect(api).to receive(:register_user).and_return(OpenStruct.new('success?': true))
          subject
        end
      end
    end
  end

  describe '#get_provider_details' do
    context 'Given a valid cobranded credentials' do
      before do
        api.cobranded_login
        api.login_user(registered_user)
      end
      subject { api.get_provider_details(provider_id) }


      context 'When a request for site info is performed the result' do
        let(:provider_id) { 16441 }

        it 'is expected to respond with the provider details and contain the login form' do
          is_expected.not_to be_nil
          is_expected.to be_kind_of(YodleeWrap::Response)
          expect(subject.body['provider']).to be_a Array
          expect(subject.body['provider'].length).to eq 1
          expect(subject.body['provider'].first['id']).to eq provider_id
          expect(subject.body['provider'].first.fetch('loginForm')).not_to be_nil
        end

        it 'the login form' do
          login_form = subject.body['provider'].first.fetch('loginForm')
          expect(login_form).to be_a Hash
          expect(login_form).to have_key 'forgetPasswordURL'
          expect(login_form).to have_key 'formType'
          expect(login_form).to have_key 'row'
          expect(login_form['row']).to be_a Array
        end
      end

      context 'no MFA' do
        let(:provider_id) { 16441 }
        it 'should indicate in the response that there is no mfa' do
          expect(subject.mfa?).to be_falsey
          expect(subject.mfa_type).to be_nil
        end
      end

      context 'with MFA - CAPTCHA' do
        let(:provider_id) { 18769 }
        it 'should indicate in the response that there is captcha MFA' do
          expect(subject.mfa?).to be_truthy
          expect(subject.mfa_type).to eq 'Image based multifactor authentication'

        end
      end

      context 'with MFA - SecurityQA' do
        let(:provider_id) { 16486 }
        it 'should indicate in the response that there is security question MFA' do
          expect(subject.mfa?).to be_truthy
          expect(subject.mfa_type).to eq 'Question and answer type multi factor authentication.'
        end
      end

      context 'with MFA - SecurityQA' do
        let(:provider_id) { 16477 }
        it 'should indicate that there is some MFA stuff going on.' do
          expect(subject.mfa?).to be_truthy
          expect(subject.mfa_type).to eq 'Question and answer type multi factor authentication.'
        end
      end
    end
  end

  describe 'add provider account - no MFA' do
    context 'Given  valid cobranded credentials' do
      context 'when #add_provider_account is called' do
        subject do
          api.cobranded_login
          api.login_user(registered_user)
          response = api.get_provider_details(16441)
          expect(response).to be_success
          login_form = response.body['provider'].first['loginForm']
          login_form['row'][0]['field'][0]['value'] = 'TheUsername.site16441.2'
          login_form['row'][1]['field'][0]['value'] = 'site16441.2'

          api.add_provider_account(16441, response.body)
        end

        it 'should create a provider account' do
          is_expected.to be_kind_of(YodleeWrap::Response)
          is_expected.to be_success
          expect(subject.body['providerAccountId']).not_to be_nil
          expect(subject.mfa?).to be_falsey
          expect(subject.body['refreshInfo']).not_to be_nil
          expect(subject.status).to eq 201
        end
      end
    end
  end

  describe '#get_provider_account_status - no MFA' do
    context 'Given a valid cobranded credentials and base_url' do
      context 'Given a user who it logged into the api' do
        context 'When #get_mfa_response_for_site is called the response' do
          subject do
            api.cobranded_login
            api.login_user(registered_user)
            response = api.get_provider_details(16441)
            expect(response).to be_success
            login_form = response.body['provider'].first['loginForm']
            login_form['row'][0]['field'][0]['value'] = 'TheUsername.site16441.2'
            login_form['row'][1]['field'][0]['value'] = 'site16441.2'

            response = api.add_provider_account(16441, response.body)
            api.get_provider_account_status(response.body['providerAccountId'])
          end

          it 'is expected be a valid response' do
            is_expected.to be_kind_of(YodleeWrap::Response)
            is_expected.to be_success
            expect(subject.body['providerAccount']).not_to be_nil
            expect(subject.body['providerAccount']['refreshInfo']).not_to be_nil
            expect(subject.status).to eq 200
          end
        end
      end
    end
  end

  describe 'MFA Workflow' do
    context 'Given  valid cobranded credentials' do
      context 'when #add_provider_account is called' do
        subject do
          api.cobranded_login
          api.login_user(registered_user)
          response = api.get_provider_details(18769)
          expect(response).to be_success
          expect(response.mfa?).to be_truthy
          login_form = response.body['provider'].first['loginForm']
          login_form['row'][0]['field'][0]['value'] = 'TheUsername.site18769.1'
          login_form['row'][1]['field'][0]['value'] = 'site18769.1'

          api.add_provider_account(18769, response.body)
        end

        it 'should create a provider account' do
          is_expected.to be_kind_of(YodleeWrap::Response)
          is_expected.to be_success
          expect(subject.body['providerAccountId']).not_to be_nil
          expect(subject.body['refreshInfo']).not_to be_nil
          expect(subject.status).to eq 201
        end

        # context 'with incorrect login credentials' do
        #   subject do
        #     api.cobranded_login
        #     api.login_user(registered_user)
        #     response = api.get_provider_details(18769)
        #     expect(response).to be_success
        #     expect(response.mfa?).to be_truthy
        #     login_form = response.body['provider'].first['loginForm']
        #     login_form['row'][0]['field'][0]['value'] = 'TheUsername.site18769.1'
        #     login_form['row'][1]['field'][0]['value'] = 'WrongPassword.site18769.1'
        #     response  = api.add_provider_account(18769, response.body)
        #     expect(response).to be_a(YodleeWrap::Response)
        #     expect(response).to be_truthy
        #     sleep(5)
        #     api.get_provider_account_status(response.body['providerAccountId'])
        #   end
        #
        #   it 'should create a provider account, but with errors when you check on the status' do
        #     is_expected.to be_a(YodleeWrap::Response)
        #     is_expected.to be_success
        #     byebug
        #     expect(subject.body['providerAccount']['refreshInfo']['statusMessage']).to eq 'LOGIN_FAILED'
        #   end
        # end
      end

    end
  end

  describe '#get_all_provider_accounts' do
    context 'given valid cobrand credentials' do
      context 'and a user who is logged in to the api' do
        context 'when #get_all_provider_accounts is called' do
          subject do
            api.cobranded_login
            api.login_user(registered_user)
            api.get_all_provider_accounts
          end
          it 'should return all provider accounts for the currently logged in user' do
            is_expected.to be_kind_of(YodleeWrap::Response)
            is_expected.to be_success
            expect(subject.body).to be_a Hash
            expect(subject.body).to have_key 'providerAccount'
            expect(subject.body['providerAccount']).to be_a Array
          end
        end
      end
    end
  end

  # describe '#put_mfa_request_for_site' do
  #   context 'Given a valid cobranded credentials and base_url' do
  #     context 'Given a user who is logged into the api' do
  #       context 'Given a user attempting to add a site with Token Based MFA' do
  #         context 'When #put_mfa_request_for_site is called the response' do
  #           subject {
  #             api.cobranded_login
  #             response = api.login_or_register_user "testuser#{rand(100...200)}", 'testpassword143', 'test@test.com'
  #
  #             response = api.get_site_login_form(16445)
  #             expect(response).to be_success
  #
  #             login_form = response.body
  #
  #             login_form['componentList'][0]['fieldValue'] = 'yodlicious1.site16445.1'
  #             login_form['componentList'][1]['fieldValue'] = 'site16445.1'
  #
  #             response = api.add_site_account(16445, login_form)
  #             expect(response).to be_success
  #
  #             expect(response.body['siteRefreshInfo']['siteRefreshMode']['refreshMode']).to eq('MFA')
  #             site_account_id = response.body['siteAccountId']
  #             response = api.get_mfa_response_for_site_and_wait site_account_id, 2
  #             expect(response.body['isMessageAvailable']).to be_truthy
  #
  #             field_info = response.body['fieldInfo']
  #             field_info['fieldValue'] = "monkeys"
  #             api.put_mfa_request_for_site site_account_id, :MFATokenResponse, field_info
  #           }
  #
  #           it 'is expected be a valid response' do
  #             is_expected.to be_kind_of(YodleeWrap::Response)
  #             is_expected.to be_success
  #             expect(subject.body['primitiveObj']).to be_truthy
  #           end
  #
  #           after { api.unregister_user }
  #         end
  #       end
  #
  #       context 'Given a user attempting to add a site with Security Question and Answer MFA' do
  #         context 'When #put_mfa_request_for_site is called the response' do
  #           subject {
  #             api.cobranded_login
  #             response = api.login_or_register_user "testuser#{rand(100...200)}", 'testpassword143', 'test@test.com'
  #
  #             response = api.get_site_login_form(16486)
  #             expect(response).to be_success
  #
  #             login_form = response.body
  #             login_form['componentList'][0]['fieldValue'] = 'yodlicious1.site16486.1'
  #             login_form['componentList'][1]['fieldValue'] = 'site16486.1'
  #
  #             response = api.add_site_account(16486, login_form)
  #             expect(response).to be_success
  #
  #             expect(response.body['siteRefreshInfo']['siteRefreshMode']['refreshMode']).to eq('MFA')
  #             site_account_id = response.body['siteAccountId']
  #             response = api.get_mfa_response_for_site_and_wait site_account_id, 2
  #             expect(response.body['isMessageAvailable']).to be_truthy
  #
  #             field_info = response.body['fieldInfo']
  #             field_info['questionAndAnswerValues'][0]['fieldValue'] = 'Texas'
  #             field_info['questionAndAnswerValues'][1]['fieldValue'] = 'w3schools'
  #             api.put_mfa_request_for_site site_account_id, :MFAQuesAnsResponse, field_info
  #           }
  #
  #           it 'is expected be a valid response' do
  #             is_expected.to be_kind_of(YodleeWrap::Response)
  #             is_expected.to be_success
  #             expect(subject.body['primitiveObj']).to be_truthy
  #           end
  #
  #           after { api.unregister_user }
  #         end
  #       end
  #
  #       context 'Given a user attempting to add a site with Captcha MFA' do
  #         context 'When #put_mfa_request_for_site is called the response' do
  #           subject do
  #             api.cobranded_login
  #             response = api.login_or_register_user "testuser#{rand(100...200)}", 'testpassword143', 'test@test.com'
  #             expect(response).to be_success
  #
  #             response = api.get_site_login_form(18769)
  #             expect(response).to be_success
  #
  #             login_form = response.body
  #             login_form['componentList'][0]['fieldValue'] = 'yodlicious1.site18769.1'
  #             login_form['componentList'][1]['fieldValue'] = 'site18769.1'
  #
  #             response = api.add_site_account(18769, login_form)
  #             expect(response).to be_success
  #
  #             expect(response.body['siteRefreshInfo']['siteRefreshMode']['refreshMode']).to eq('MFA')
  #             site_account_id = response.body['siteAccountId']
  #             response = api.get_mfa_response_for_site_and_wait site_account_id, 2
  #             expect(response.body['isMessageAvailable']).to be_truthy
  #
  #             field_info = response.body['fieldInfo']
  #             field_info['fieldValue'] = "monkeys"
  #             api.put_mfa_request_for_site site_account_id, :MFAImageResponse, field_info
  #           end
  #
  #           it 'is expected be a valid response' do
  #             is_expected.to be_kind_of(YodleeWrap::Response)
  #             is_expected.to be_success
  #             expect(subject.body['primitiveObj']).to be_truthy
  #           end
  #
  #           after { api.unregister_user }
  #         end
  #       end
  #     end
  #   end
  # end

  # describe 'the yodlee apis fetching summary data about registered site accounts endpoints' do
  #   context 'Given a registered user with registered accounts' do
  #     before {
  #       api.cobranded_login
  #       api.login_user "testuser_with_transactions@liftforward.com", 'testpassword143'
  #       # api.register_user "testuser#{rand(100..999)}", 'testpassword143', 'test@test.com'
  #       # dag_login_form[:componentList][0][:value] = 'yodlicious.site16441.1'
  #       # dag_login_form[:componentList][1][:value] = 'site16441.1'
  #       # api.add_site_account_and_wait(16441, dag_login_form)
  #     }
  #
  #     context 'when getAllSiteAccounts is called the return' do
  #       subject { api.get_all_site_accounts }
  #
  #       it 'is expected to return an array containing 1 siteAccount' do
  #         # puts JSON.pretty_generate(subject)
  #         is_expected.to be_success
  #         expect(subject.body).to be_kind_of(Array)
  #         expect(subject.body.length).to be > 0
  #         expect(subject.body[0]['siteAccountId']).not_to be_nil
  #         expect(subject.body[0]['siteRefreshInfo']['siteRefreshStatus']['siteRefreshStatus']).to eq('REFRESH_COMPLETED')
  #
  #       end
  #     end
  #
  #     context 'when getItemSummariesForSite is called the return' do
  #       subject {
  #         site_accounts = api.get_all_site_accounts
  #         # puts site_accounts[0]['siteAccountId']
  #         # puts JSON.pretty_generate(site_accounts)
  #         api.get_item_summaries_for_site(site_accounts.body[0]['siteAccountId'])
  #       }
  #
  #       it 'is expected to return an array site summaries' do
  #         # puts JSON.pretty_generate(subject)
  #
  #         is_expected.to be_kind_of(YodleeWrap::Response)
  #         is_expected.to be_success
  #         expect(subject.body[0]['itemId']).not_to be_nil
  #       end
  #     end
  #
  #     context 'when getItemSummaries is called the return' do
  #       subject { api.get_item_summaries }
  #
  #       it 'is expected to return an array of site summaries' do
  #         # puts JSON.pretty_generate(subject)
  #
  #         is_expected.to be_kind_of(YodleeWrap::Response)
  #         is_expected.to be_success
  #         expect(subject.body.length).to be > 0
  #         expect(subject.body[0]['itemId']).not_to be_nil
  #       end
  #     end
  #   end
  # end

  # describe 'the yodlee apis fetching user/s transactions' do
  #   context 'Given a registered user with registered accounts' do
  #     before {
  #       api.cobranded_login
  #       api.login_or_register_user 'testuser_with_transactions@liftforward.com', 'testpassword143', 'testuser_with_transactions@liftforward.com'
  #       dag_login_form['componentList'][0]['fieldValue'] = 'yodlicious.site16441.1'
  #       dag_login_form['componentList'][1]['fieldValue'] = 'site16441.1'
  #       api.add_site_account(16441, dag_login_form)
  #     }
  #
  #     context 'When a transaction search for all transactions is performed the result' do
  #       subject { api.execute_user_search_request }
  #
  #       it 'is expected to return a valid search result' do
  #         # puts JSON.pretty_generate(subject.body)
  #
  #         is_expected.not_to be_nil
  #         is_expected.to be_kind_of(YodleeWrap::Response)
  #         is_expected.to be_success
  #         expect(subject.body['errorOccurred']).to be_nil
  #         expect(subject.body['searchIdentifier']).not_to be_nil
  #         expect(subject.body['searchResult']['transactions']).to be_kind_of(Array)
  #         expect(subject.body['searchResult']['transactions'].length).to be > 0
  #       end
  #     end
  #   end
  # end

  pending 'downloading transaction history'
  pending 'fetching a list of content services'
  pending 'failing to create a new session'
  pending 'failing when running a search for a site'

  let(:dag_login_form) {
    JSON.parse('{
      "conjunctionOp": {
        "conjuctionOp": 1
      },
      "componentList": [
        {
          "valueIdentifier": "LOGIN1",
          "valueMask": "LOGIN_FIELD",
          "fieldType": {
            "typeName": "IF_LOGIN"
          },
          "size": 20,
          "maxlength": 40,
          "name": "LOGIN1",
          "displayName": "Catalog",
          "isEditable": true,
          "isOptional": false,
          "isEscaped": false,
          "helpText": "150862",
          "isOptionalMFA": false,
          "isMFA": false
        },
        {
          "valueIdentifier": "PASSWORD1",
          "valueMask": "LOGIN_FIELD",
          "fieldType": {
            "typeName": "IF_PASSWORD"
          },
          "size": 20,
          "maxlength": 40,
          "name": "PASSWORD1",
          "displayName": "Password",
          "isEditable": true,
          "isOptional": false,
          "isEscaped": false,
          "helpText": "150863",
          "isOptionalMFA": false,
          "isMFA": false
        }
      ],
      "defaultHelpText": "16103"
    }')
  }
end
