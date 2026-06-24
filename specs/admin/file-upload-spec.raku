use BDD::Behave;
use MVC::Keayl::Admin;
use MVC::Keayl::Admin::Attachments;
use MVC::Keayl::Routing;
use MVC::Keayl::Dispatcher;
use MVC::Keayl::Request;
use MVC::Keayl::Admin::TestSupport;

sub host {
  my $router = routes { mount MVC::Keayl::Admin.endpoint, at => '/admin'; };
  MVC::Keayl::Dispatcher.new(:$router, controllers => []);
}

sub fetch(Str:D $path) {
  host.call(MVC::Keayl::Request.new(method => 'GET', target => $path))
}

sub upload(Str:D $path, %text, :$file-field, :$filename, :$content, :$content-type = 'image/png') {
  my $boundary = 'KEAYLBOUNDARY';
  my $body = '';

  for %text.kv -> $name, $value {
    $body ~= "--$boundary\r\nContent-Disposition: form-data; name=\"$name\"\r\n\r\n$value\r\n";
  }

  if $file-field {
    $body ~= "--$boundary\r\nContent-Disposition: form-data; name=\"$file-field\"; filename=\"$filename\"\r\nContent-Type: $content-type\r\n\r\n$content\r\n";
  }

  $body ~= "--$boundary--\r\n";

  host.call(MVC::Keayl::Request.new(
    method  => 'POST',
    target  => $path,
    headers => { 'Content-Type' => "multipart/form-data; boundary=$boundary" },
    body    => $body,
  ))
}

describe 'MVC::Keayl::Admin file uploads', {
  before-each {
    MVC::Keayl::Admin.reset;
    setup-admin-db;
    register-posts;
    register-authors;
  }

  it 'renders a multipart form with a file input', {
    my $body = fetch('/admin/posts/new').body;
    expect($body.contains('enctype="multipart/form-data"') && $body.contains('type="file"')).to.be-truthy;
  }

  it 'attaches an uploaded file on create', {
    my $response = upload('/admin/posts', { title => 'With cover', body => 'b' },
      file-field => 'cover', filename => 'cover.png', content => 'PNGBYTES');

    expect($response.status).to.be(302);
  }

  it 'stores the attachment with its filename', {
    upload('/admin/posts', { title => 'With cover', body => 'b' },
      file-field => 'cover', filename => 'cover.png', content => 'PNGBYTES');

    my $post = Post.where({ title => 'With cover' }).first;
    expect(MVC::Keayl::Admin::Attachments.attachment-for($post, 'cover').blob.filename).to.be('cover.png');
  }

  it 'attaches nothing when no file is uploaded', {
    upload('/admin/posts', { title => 'No cover', body => 'b' });

    my $post = Post.where({ title => 'No cover' }).first;
    expect(MVC::Keayl::Admin::Attachments.attachment-for($post, 'cover').defined).to.be-falsy;
  }
}
