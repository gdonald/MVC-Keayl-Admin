use v6.d;
use ORM::ActiveRecord::Relation::Query::Like;

unit module MVC::Keayl::Admin::Predicate;

constant PREDICATES = set <eq not-eq cont starts ends gt gteq lt lteq in between present blank true false>;

my sub coerce($value) {
  ($value ~~ Str && $value ~~ /^ '-'? \d+ ['.' \d+]? $/) ?? +$value !! $value
}

sub apply-predicate($relation, Str:D $column, Str:D $predicate, $value --> Mu) is export {
  given $predicate {
    when 'eq'      { $relation.where({ $column => coerce($value) }) }
    when 'not-eq'  { $relation.where.not({ $column => coerce($value) }) }
    when 'cont'    { $relation.where({ $column => LikePredicate.contains($value.Str) }) }
    when 'starts'  { $relation.where({ $column => LikePredicate.starts-with($value.Str) }) }
    when 'ends'    { $relation.where({ $column => LikePredicate.ends-with($value.Str) }) }
    when 'gt'      { $relation.where({ $column => coerce($value) ^.. * }) }
    when 'gteq'    { $relation.where({ $column => coerce($value) .. * }) }
    when 'lt'      { $relation.where({ $column => * ..^ coerce($value) }) }
    when 'lteq'    { $relation.where({ $column => * .. coerce($value) }) }
    when 'in'      { $relation.where({ $column => $value.Str.split(',').map(*.trim).map(&coerce).list }) }
    when 'between' { my @b = $value.Str.split(',').map(*.trim); $relation.where({ $column => coerce(@b[0]) .. coerce(@b[1]) }) }
    when 'present' { $relation.where.not({ $column => Nil }) }
    when 'blank'   { $relation.where({ $column => Nil }) }
    when 'true'    { $relation.where({ $column => True }) }
    when 'false'   { $relation.where({ $column => False }) }
    default        { die "unknown filter predicate '$predicate'" }
  }
}
