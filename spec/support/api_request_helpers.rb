module Spec
  module Support
    module ApiRequestHelpers
      def get(path, **args)
        process(:get, path, **args)
      end

      def post(path, **args)
        process(:post, path, **args)
      end

      def process(method, path, params: nil, headers: nil, env: nil, xhr: false, as: nil)
        headers = request_headers.merge(Hash(headers))
        super(method, path, params: params, headers: headers, env: env, xhr: xhr, as: :json)
      end

      def request_headers
        @request_headers ||= {}
      end

      def init_api
        @enterprise = FactoryBot.create(:miq_enterprise)
        @guid, @server, @zone = EvmSpecHelper.create_guid_miq_server_zone
        @region = FactoryBot.create(:miq_region, :region => ApplicationRecord.my_region_number)
        @role   = FactoryBot.create(:miq_user_role, :name => "API Role")
        @group  = FactoryBot.create(:miq_group, :description => "API Group", :miq_user_role => @role)
        @user   = FactoryBot.create(:user, :name => "API User", :userid => "api_userid", :password => "api_password", :miq_groups => [@group])
      end

      def api_basic_authorize(*identifiers, user: @user.userid, password: @user.password)
        if identifiers.present?
          identifiers.flatten.collect do |identifier|
            @role.miq_product_features << MiqProductFeature.find_or_create_by(:identifier => identifier) if identifier
          end
          @role.save

          MiqProductFeature.seed_tenant_miq_product_features if identifiers & MiqProductFeature::TENANT_FEATURE_ROOT_IDENTIFIERS == identifiers
        end

        request_headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
      end
    end
  end
end
