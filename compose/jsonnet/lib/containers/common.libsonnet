{
  mapMixin(array, key_name, key_value, value):: std.map(
    function(e) if e[key_name] == key_value then e + value else e,
    array
  ),
}
