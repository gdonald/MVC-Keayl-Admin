use v6.d;
use MVC::Keayl::Admin::Controller;

unit class MVC::Keayl::Admin::DashboardController is MVC::Keayl::Admin::Controller;

method index {
  self.render-admin(
    'dashboard/index',
    page-title  => 'Dashboard',
    breadcrumbs => [ 'Dashboard' => Nil ],
  )
}
