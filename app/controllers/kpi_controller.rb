class KpiController < ApplicationController
  unloadable
  helper_method :find_issues
	
  def find_issues(project)
    issues = []
        
    proj = Project.find(project)
    issues = issues +  proj.issues
        
    #Read subprojects
    subprj = Project.where('parent_id = ? ', project)
    print subprj.size()
    subprj.each do|p|
      issues = issues + self.find_issues(p.id) 
    end

    return issues
  end 


  class WhenTuple < Struct.new(:month,:year)
	def <=>(other)
          self[:year] * 100  + self[:month] <=> other[:year] * 100 +   other[:month] 
        end
  end 
 
  def index

    project = Project.find(params[:project_id])
    @project = project   

    #find issues in the project and subprojects
    issues = self.find_issues(project.id)
   
    #Datasets
    xitems = []
    created = Hash.new
    closed = Hash.new
    effortEstimated = Hash.new

    issues.each do |issue|
      #Created
      when_created = WhenTuple.new
      when_closed = WhenTuple.new
      when_created.month = issue.created_on.month
      when_created.year = issue.created_on.year

      #Created count 
      if created.has_key?(when_created)
        created[when_created] = created[when_created] + 1 
      else
	created[when_created] = 1
      end 
      
      #Closed count  
      if not issue.closed_on.nil?  
        when_closed.month = issue.closed_on.month
        when_closed.year = issue.closed_on.year
 
        if closed.has_key?(when_closed)
          closed[when_closed] = closed[when_closed] + 1  
        else
          closed[when_closed] = 1
        end
      end

      #Effort Count
      if not issue.estimated_hours.nil? 
        if effortEstimated.has_key?(when_created)
          effortEstimated[when_created] = effortEstimated[when_created] + issue.estimated_hours
        else
          effortEstimated[when_created] = issue.estimated_hours 
        end  
      end
    end 


    #prepare charts
    createdArray = []
    closedArray = []
    effortArray = []
    (created.keys & closed.keys).sort.each do |xitem|
      if not closed.has_key?(xitem) 
        closed[xitem] = 0
      end
      if not created.has_key?(xitem) 
        created[xitem] = 0
      end
      if not effortEstimated.has_key?(xitem)
        effortEstimated[xitem] = 0
      end
      effortArray << effortEstimated[xitem]
      createdArray << created[xitem]
      closedArray << closed[xitem] 
      xitems << I18n.t("date.abbr_month_names")[xitem.month] + xitem.year.to_s() 
    end 

    g =  Gchart.line(:title => "Reported / Closed",
            :data => [createdArray, closedArray],
            :size => '700x400',			
            :line_colors => "FF0000,00FF00",
            :axis_with_labels => 'x,r',
            :legend => ["Reported", "Closed"],
            :axis_range => [nil, [0,(createdArray & closedArray).max, 10]],
            :axis_labels => [xitems, []])
    @gcreated_closed = g

    g =  Gchart.line(:title => "Effort Estimated ( Hours ) ",
            :data => [effortArray],
            :size => '700x400',
            :line_colors => "00FF00",
            :axis_with_labels => 'x,r',
            :axis_labels => [xitems, []],
            :axis_range => [nil, [0,effortArray.max, 20]])

    @gestimatedeffort = g 
  end 

end
