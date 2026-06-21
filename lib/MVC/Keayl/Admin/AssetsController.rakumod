use v6.d;
use MVC::Keayl::Controller;
use MVC::Keayl::Admin::Paths;

unit class MVC::Keayl::Admin::AssetsController is MVC::Keayl::Controller;

method show {
  my $path = self.params<path>;

  return self.head(404) without $path;
  return self.head(404) if $path.contains('..');

  my $file = assets-path().IO.add($path);

  return self.head(404) unless $file.e && $file.f;

  self.send-file($file, disposition => 'inline');
  self.response.set-header('Cache-Control', 'public, max-age=31536000, immutable');

  self.response
}
