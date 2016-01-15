<?php

use
    Sabre\DAV;

// The autoloader
require 'vendor/autoload.php';

// Now we're creating a whole bunch of objects
$rootDirectory = new DAV\FS\Directory('/var/www/drupal/sites');

// The server object is responsible for making sense out of the WebDAV protocol
$server = new DAV\Server($rootDirectory);

// If your server is not on your webroot, make sure the following line has the
// correct information
$server->setBaseUri('/');

// The lock manager is reponsible for making sure users don't overwrite
// each others changes.
$lockBackend = new DAV\Locks\Backend\File('locks');
$lockPlugin = new DAV\Locks\Plugin($lockBackend);
$server->addPlugin($lockPlugin);

// All we need to do now, is to fire up the server
$server->exec();

?>
