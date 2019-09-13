describe :placeholders do
  include_examples :placeholders, Cfme::CloudServices::Engine.root.join('locale').to_s
end
