define :nginx_vhost, :unicorn => false do
  sitename = params[:name]
  rootdir = "#{node['nginx_vhost']['root']}/#{sitename}"

  directory "#{node['nginx_vhost']['root']}" do
    mode '0755'
    owner 'app'
    group 'app'
    action :create
  end

  directory "#{rootdir}" do
    mode '0755'
    owner 'app'
    group 'app'
    action :create
  end

  if params[:unicorn]
    directory "#{rootdir}/app" do
      mode '0755'
      owner 'app'
      group 'app'
      action :create
    end
  else
    directory "#{rootdir}/html" do
      mode '0755'
      owner 'app'
      group 'app'
      action :create
    end
  end

  directory "#{rootdir}/logs" do
    mode '0755'
    owner 'www-data'
    group 'www-data'
    action :create
  end

  logrotate_app "#{sitename}-nginx-log" do
    cookbook "logrotate"
    path "#{rootdir}/logs/*.log"
    frequency "daily"
    rotate 400
    create "644 www-data www-data"
    options ["compress", "dateext", "delaycompress", "missingok"]
    sharedscript true
    postrotate "[ ! -f #{node['nginx']['pid']} ]|| kill -USR1 `cat #{node['nginx']['pid']}`"
  end

  if params[:unicorn]
    logrotate_app "#{sitename}-unicorn-log" do
      cookbook "logrotate"
      path "#{rootdir}/app/shared/log/*.log"
      frequency "daily"
      rotate 400
      create "644 app app"
      options ["compress", "dateext", "delaycompress", "missingok"]
      sharedscript true
      postrotate "[ ! -f #{rootdir}/app/current/tmp/pids/unicorn.pid ]|| kill -USR1 `cat #{rootdir}/app/current/tmp/pids/unicorn.pid`"
    end
  end

  template "/etc/nginx/sites-available/#{sitename}" do
    source "#{sitename}.erb"
    mode '0644'
    action :create
  end
  nginx_site "#{sitename}"
end
