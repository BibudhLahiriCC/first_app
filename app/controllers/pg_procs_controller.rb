class PgProcsController < ApplicationController
  # GET /pg_procs
  # GET /pg_procs.xml
  def index
    @pg_procs = PgProc.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pg_procs }
    end
  end

  # GET /pg_procs/1
  # GET /pg_procs/1.xml
  def show
    @pg_proc = PgProc.test_proc(:integer, params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pg_proc }
      format.json  #show.json.erb
    end
  end

  # GET /pg_procs/new
  # GET /pg_procs/new.xml
  def new
    @pg_proc = PgProc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pg_proc }
    end
  end

  # GET /pg_procs/1/edit
  def edit
    @pg_proc = PgProc.find(params[:id])
  end

  # POST /pg_procs
  # POST /pg_procs.xml
  def create
    @pg_proc = PgProc.new(params[:pg_proc])

    respond_to do |format|
      if @pg_proc.save
        format.html { redirect_to(@pg_proc, :notice => 'Pg proc was successfully created.') }
        format.xml  { render :xml => @pg_proc, :status => :created, :location => @pg_proc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pg_proc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pg_procs/1
  # PUT /pg_procs/1.xml
  def update
    @pg_proc = PgProc.find(params[:id])

    respond_to do |format|
      if @pg_proc.update_attributes(params[:pg_proc])
        format.html { redirect_to(@pg_proc, :notice => 'Pg proc was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pg_proc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pg_procs/1
  # DELETE /pg_procs/1.xml
  def destroy
    @pg_proc = PgProc.find(params[:id])
    @pg_proc.destroy

    respond_to do |format|
      format.html { redirect_to(pg_procs_url) }
      format.xml  { head :ok }
    end
  end
end
