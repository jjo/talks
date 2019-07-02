// Return a hashed name with data's md5
{
  hashed_name(name, data):: (
    "%s-%s" % [name, std.substr(std.md5(std.toString(data)), 0, 7)]
  ),
}
