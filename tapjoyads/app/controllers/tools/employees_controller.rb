class Tools::EmployeesController < WebsiteController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  # GET /employees_url
  # GET /employees.xml
  def index
    @employees = Employee.find(:all,
                               :order => 'last_name, first_name')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @employees }
    end
  end

  # GET /employees/1
  # GET /employees/1.xml
  def show
    @employee = Employee.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/new
  # GET /employees/new.xml
  def new
    @employee = Employee.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/1/edit
  def edit
    @employee = Employee.find(params[:id])
  end

  # POST /employees
  # POST /employees.xml
  def create
    @employee = Employee.new(params[:employee])

    respond_to do |format|
      if @employee.save
        flash[:notice] = 'Employee was successfully created.'
        format.html { redirect_to(tools_employees_url) }
        format.xml  { render :xml => @employee, :status => :created, :location => @employee }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /employees/1
  # PUT /employees/1.xml
  def update
    @employee = Employee.find(params[:id])

    respond_to do |format|
      if @employee.update_attributes(params[:employee])
        flash[:notice] = 'Employee was successfully updated.'
        format.html { redirect_to(tools_employees_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.xml
  def destroy
    @employee = Employee.find(params[:id])
    @employee.destroy

    respond_to do |format|
      format.html { redirect_to(tools_employees_url) }
      format.xml  { head :ok }
    end
  end

  def show_photo
    @employee = Employee.find(params[:id])
    if @employee.photo
      send_data(@employee.photo, :filename => @employee.photo_file_name, :type => @employee.photo_content_type, :disposition => 'inline')
    else
      send_file('public/images/site/blank_image.jpg', :type => 'image/jpg', :disposition => 'inline')
    end
  end
  
  def delete_photo
    @employee = Employee.find(params[:id])
    @employee.delete_photo

    respond_to do |format|
      if @employee.save
          flash[:notice] = 'Employee photo was successfully removed.'
          format.html { redirect_to(tools_employees_url) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end
end
