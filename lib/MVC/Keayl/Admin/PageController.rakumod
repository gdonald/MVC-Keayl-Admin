use v6.d;
use MVC::Keayl::Admin::Controller;
use MVC::Keayl::Admin::Pages;

unit class MVC::Keayl::Admin::PageController is MVC::Keayl::Admin::Controller;

method show {
  my $slug = self.request.path.split('/').grep(*.chars).head;
  my $page = MVC::Keayl::Admin::Pages.by-slug($slug);

  return self.head(404) without $page;

  self.assign('admin_page_body', $page.block.(self));

  self.render-admin(
    'page/show',
    page-title  => $page.title,
    breadcrumbs => [ $page.title => Nil ],
  )
}
