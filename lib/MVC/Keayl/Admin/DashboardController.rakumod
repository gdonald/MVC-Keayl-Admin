use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Config;
use MVC::Keayl::Admin::Dashboard;

unit class MVC::Keayl::Admin::DashboardController is MVC::Keayl::Admin::Controller;

method index {
  my $mount = MVC::Keayl::Admin::Config.current.mount-path;

  self.assign('dashboard_blocks', MVC::Keayl::Admin::Dashboard.render(:$mount));

  self.render-admin(
    'dashboard/index',
    page-title => 'Dashboard',
  )
}
