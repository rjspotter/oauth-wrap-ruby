require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module OauthWrap
  AUTH_URL = "https://example.org/authorize"
  
  describe WebApp, '#continue' do
    before :each do
      WebMock.reset_webmock
      @web_app = OauthWrap.as_web_app :authorization_url => AUTH_URL
    end
  
    it "fails without necessary parameters" do
      lambda {
        @web_app.continue :some_key => 42 
      }.should raise_error(OauthWrap::MissingParameters) 
    end
    
    it "issues a POST request" do
      WebMock.stub_request(:post, AUTH_URL).to_return(:body => "wrap_refresh_token=refresh_me&wrap_access_token=ACCESS_OK")
      @web_app.continue :wrap_verification_code => "deadbeef"
    end
    
    it "raises an exception if verification code was illegal" do
      WebMock.stub_request(:post, AUTH_URL).to_return(
        :body => "wrap_error_reason=expired_verification_code",
        :status => ["400", "Bad Request"]
      )
        
      lambda {
        @web_app.continue :wrap_verification_code => "deadbeef"   
      }.should raise_error(OauthWrap::RequestFailed)
    end
    
    it "raises an exception an unexpected response-code occured" do
      WebMock.stub_request(:post, AUTH_URL).to_return(
        :body => "wrap_error_reason=expired_verification_code",
        :status => ["401", "Unauthorized"]
      )
        
      lambda {
        @web_app.continue :wrap_verification_code => "deadbeef"   
      }.should raise_error(OauthWrap::RequestFailed)
    end
    
    it "raises an exception if credentials are invalid" do
      WebMock.stub_request(:post, AUTH_URL).to_return(
        :body => "wrap_error_reason=expired_verification_code",
        :status => ["401", "Unauthorized"],
        :headers => { "WWW-Authenticate" => "WRAP" }
      )
      
      lambda {
         @web_app.continue :wrap_verification_code => "deadbeef"          
      }.should raise_error(OauthWrap::InvalidCredentials)
    end
  end
end