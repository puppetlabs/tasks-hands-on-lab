plan example8::packages(String $nodes, String $package = "openssl") {
  $all = $nodes.split(",")
  $minifacts = run_task('minifact', $all)

  $debian = $all.filter |$nd| { $minifacts[$nd][os][family] == "Debian" }
  $redhat = $all.filter |$nd| { $minifacts[$nd][os][family] == "RedHat" }

  $rpms = run_task('example8::rpm', $redhat, package => $package)
  $debs = run_task('example8::dpkg', $debian, package => $package)

  $rpms.each |$nd, $out| { example8::print_node_result($nd, $out, "rpm") }
  $debs.each |$nd, $out| { example8::print_node_result($nd, $out, "deb") }

  undef
}
