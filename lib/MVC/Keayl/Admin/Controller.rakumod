use v6.d;
use MVC::Keayl::Controller;
use MVC::Keayl::Admin::Config;

class MVC::Keayl::Admin::Controller is MVC::Keayl::Controller {
  has %.admin-context;

  method set-admin-context {
    %!admin-context = {
      site-title => MVC::Keayl::Admin::Config.current.site-title,
      path       => self.request.defined ?? self.request.path !! '',
    };
  }
}

MVC::Keayl::Admin::Controller.before-action('set-admin-context');
