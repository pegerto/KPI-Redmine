require 'redmine'
require 'gchart'

Redmine::Plugin.register :kpi do
  name 'Key perfomance indicator'
  author 'Pegerto'
  description	'Reporting metrics for redmine'  
  version '0.0.1'

  project_module :kpi do
    permission :view_kpi, :kpi => :index
  end


  menu :project_menu, :kpi, { :controller => 'kpi', :action => 'index' }, :caption => 'KPI', :param => :project_id
	

end
