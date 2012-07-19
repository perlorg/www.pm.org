# app.psgi for prereviewing the generated content

use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::DirIndex;

my $app = Plack::App::File->new({ root => './' })->to_app;

builder {
      enable "Plack::Middleware::DirIndex", dir_index => 'index.html';
      $app;
}
