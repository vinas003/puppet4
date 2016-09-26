define easy_file ($mode = "644", $owner = "root", $group = "root") {

    $dirname  = dirname($name)
    $filename = basename($name)

    $services = getvar("${caller_module_name}::services")
    $packages = getvar("${caller_module_name}::packages")

    # Here we set the files definitions, root:root with 644 are default premissions
    file { "$name":   	             # Name is like the filepath
      path    => $name,              # The filepath
      mode    => $mode,              # Set permissions
      owner   => $owner,             # Set owner
      group   => $group,             # Set group
      notify  => Service[$services], # It should notify the service named if the file changes
      require => Package[$packages], # Require its packages

      # the puppetmaster find this file in path-to-puppet-modules/caller_module/templates/$filename.erb .erb since its a template
      content => template("${caller_module_name}/${filename}.erb"), 
  }
}
