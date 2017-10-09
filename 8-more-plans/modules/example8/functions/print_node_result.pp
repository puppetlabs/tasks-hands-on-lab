function example8::print_node_result(String $nd, $out, String $kind) {
  $out[result].each |$res| {
    util::print("$nd: ${res[name]} ${res[version]} ${res[arch]} $kind")
  }
}
