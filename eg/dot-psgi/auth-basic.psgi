use v5.38;

use Plack::Builder;
use Authen::Simple::Passwd;
use Log::Log4perl; # For additional logging from Authen::Simple::Passwd

Log::Log4perl -> easy_init();

builder {

  enable 'Auth::Basic' ,
    realm         => 'My Plack Perl Web Server' ,
    authenticator => Authen::Simple::Passwd -> new(
      path => "$ENV{HOME}/.htpasswd" , # File: <user>:<password>
      log  => Log::Log4perl -> get_logger( 'Authen::Simple::Passwd' ) ,
    );

  sub {
    return [ 200 ,
      [ 'Content-Type' => 'text/plain' ] ,
      [ 'Some text' . rand ]
    ];
  }

};
