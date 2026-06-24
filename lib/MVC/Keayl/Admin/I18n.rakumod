use v6.d;
use MVC::Keayl::I18n;
use MVC::Keayl::Admin::Inflection;

unit class MVC::Keayl::Admin::I18n;

my $backend;

method backend(::?CLASS:U: --> MVC::Keayl::I18n) {
  $backend //= MVC::Keayl::I18n.new(default-locale => 'en')
}

method use-backend(::?CLASS:U: $new --> Nil) {
  $backend = $new;
}

method load-locales(::?CLASS:U: $dir --> Nil) {
  self.backend.load-locales($dir);
}

method set-locale(::?CLASS:U: Str:D $locale --> Nil) {
  self.backend.set-locale($locale);
}

method reset(::?CLASS:U: --> Nil) {
  $backend = Nil;
}

method attribute-label(::?CLASS:U: $model, Str:D $name --> Str) {
  self.backend.human-attribute-name($model, $name)
}

method scope-label(::?CLASS:U: Str:D $name --> Str) {
  self.backend.translate("keayl_admin.scopes.$name", default => $name)
}

method action-label(::?CLASS:U: Str:D $name --> Str) {
  self.backend.translate("keayl_admin.actions.$name", default => humanize($name))
}

method chrome(::?CLASS:U: Str:D $key, Str:D $default --> Str) {
  self.backend.translate("keayl_admin.chrome.$key", default => $default)
}
