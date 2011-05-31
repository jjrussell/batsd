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
        if params[:upload_photo].blank?
          clear_photo(@employee)
        else
          @employee.save_photo!(params[:upload_photo].read)
        end
        flash[:notice] = 'Employee was successfully created.'
        format.html { redirect_to(edit_tools_employee_url(@employee)) }
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
        unless params[:upload_photo].blank?
          @employee.save_photo!(params[:upload_photo].read)
        end
        flash[:notice] = 'Employee was successfully updated.'
        format.html { redirect_to(edit_tools_employee_url(@employee)) }
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

  def delete_photo
    @employee = Employee.find(params[:id])
    clear_photo(@employee)

    respond_to do |format|
      flash[:notice] = 'Employee photo was successfully removed.'
      format.html { redirect_to(edit_tools_employee_url(@employee)) }
      format.xml  { head :ok }
    end
  end
  
private

  def clear_photo(employee)
    File.open("public/images/site/blank_image.jpg", 'rb') do |file|
      employee.save_photo!(file.read)
    end
  end
end
