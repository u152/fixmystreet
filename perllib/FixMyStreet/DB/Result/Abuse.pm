package FixMyStreet::DB::Result::Abuse;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FilterColumn", "InflateColumn::DateTime");
__PACKAGE__->table("abuse");
__PACKAGE__->add_columns("email", { data_type => "text", is_nullable => 0 });
__PACKAGE__->set_primary_key("email");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-24 15:32:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Bc0deuJiQlKyMGzLTUAIxg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
