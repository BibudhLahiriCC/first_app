require 'test_helper'

class PgProcsControllerTest < ActionController::TestCase
  setup do
    @pg_proc = pg_procs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pg_procs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pg_proc" do
    assert_difference('PgProc.count') do
      post :create, :pg_proc => @pg_proc.attributes
    end

    assert_redirected_to pg_proc_path(assigns(:pg_proc))
  end

  test "should show pg_proc" do
    get :show, :id => @pg_proc.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @pg_proc.to_param
    assert_response :success
  end

  test "should update pg_proc" do
    put :update, :id => @pg_proc.to_param, :pg_proc => @pg_proc.attributes
    assert_redirected_to pg_proc_path(assigns(:pg_proc))
  end

  test "should destroy pg_proc" do
    assert_difference('PgProc.count', -1) do
      delete :destroy, :id => @pg_proc.to_param
    end

    assert_redirected_to pg_procs_path
  end
end
