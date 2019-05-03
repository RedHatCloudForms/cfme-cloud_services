Vmdb::Gettext::Domains.add_domain(
  'Cfme::CloudServices',
  Cfme::CloudServices::Engine.root.join('locale').to_s,
  :po
)
