package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes(qw/
  Artist
  BindType
  Employee
  CD
  Genre
  Bookmark
  Link
  Track
  Tag
  Year2000CDs
  Year1999CDs
  Money
  /,
  { 'DBICTest::Schema' => [qw/
    LinerNotes
    Artwork
    Artwork_to_Artist
    Lyrics
    LyricVersion
    OneKey
    TwoKeys
    Serialized
  /]},
  (
    'FourKeys',
    'FourKeys_to_TwoKeys',
    'SelfRef',
    'ArtistUndirectedMap',
    'Producer',
    'CD_to_Producer',
  ),
  qw/SelfRefAlias Event NoPrimaryKey/,
  qw/Collection CollectionObject Owners BooksInLibrary/,
  qw/ForceForeign Encoded PunctuatedColumnName/,
);

1;
