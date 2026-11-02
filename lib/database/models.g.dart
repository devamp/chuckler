// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetDbPostCollection on Isar {
  IsarCollection<DbPost> get dbPosts => this.collection();
}

const DbPostSchema = CollectionSchema(
  name: r'DbPost',
  id: 9173651811291394971,
  properties: {
    r'answer': PropertySchema(
      id: 0,
      name: r'answer',
      type: IsarType.string,
    ),
    r'dislikes': PropertySchema(
      id: 1,
      name: r'dislikes',
      type: IsarType.long,
    ),
    r'likes': PropertySchema(
      id: 2,
      name: r'likes',
      type: IsarType.long,
    ),
    r'mine': PropertySchema(
      id: 3,
      name: r'mine',
      type: IsarType.bool,
    ),
    r'postId': PropertySchema(
      id: 4,
      name: r'postId',
      type: IsarType.string,
    ),
    r'promptDateId': PropertySchema(
      id: 5,
      name: r'promptDateId',
      type: IsarType.string,
    ),
    r'promptId': PropertySchema(
      id: 6,
      name: r'promptId',
      type: IsarType.string,
    ),
    r'seen': PropertySchema(
      id: 7,
      name: r'seen',
      type: IsarType.bool,
    ),
    r'uid': PropertySchema(
      id: 8,
      name: r'uid',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 9,
      name: r'username',
      type: IsarType.string,
    ),
    r'wins': PropertySchema(
      id: 10,
      name: r'wins',
      type: IsarType.long,
    )
  },
  estimateSize: _dbPostEstimateSize,
  serialize: _dbPostSerialize,
  deserialize: _dbPostDeserialize,
  deserializeProp: _dbPostDeserializeProp,
  idName: r'id',
  indexes: {
    r'postId': IndexSchema(
      id: -544810920068516617,
      name: r'postId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'postId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dbPostGetId,
  getLinks: _dbPostGetLinks,
  attach: _dbPostAttach,
  version: '3.4.1',
);

int _dbPostEstimateSize(
  DbPost object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.answer;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.postId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.promptDateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.promptId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.uid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.username;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbPostSerialize(
  DbPost object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.answer);
  writer.writeLong(offsets[1], object.dislikes);
  writer.writeLong(offsets[2], object.likes);
  writer.writeBool(offsets[3], object.mine);
  writer.writeString(offsets[4], object.postId);
  writer.writeString(offsets[5], object.promptDateId);
  writer.writeString(offsets[6], object.promptId);
  writer.writeBool(offsets[7], object.seen);
  writer.writeString(offsets[8], object.uid);
  writer.writeString(offsets[9], object.username);
  writer.writeLong(offsets[10], object.wins);
}

DbPost _dbPostDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbPost(
    reader.readStringOrNull(offsets[4]),
    reader.readStringOrNull(offsets[0]),
    reader.readStringOrNull(offsets[9]),
    reader.readStringOrNull(offsets[8]),
    reader.readLongOrNull(offsets[2]),
    reader.readLongOrNull(offsets[1]),
    reader.readLongOrNull(offsets[10]),
    reader.readStringOrNull(offsets[6]),
    reader.readStringOrNull(offsets[5]),
  );
  object.id = id;
  object.mine = reader.readBool(offsets[3]);
  object.seen = reader.readBool(offsets[7]);
  return object;
}

P _dbPostDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbPostGetId(DbPost object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbPostGetLinks(DbPost object) {
  return [];
}

void _dbPostAttach(IsarCollection<dynamic> col, Id id, DbPost object) {
  object.id = id;
}

extension DbPostByIndex on IsarCollection<DbPost> {
  Future<DbPost?> getByPostId(String? postId) {
    return getByIndex(r'postId', [postId]);
  }

  DbPost? getByPostIdSync(String? postId) {
    return getByIndexSync(r'postId', [postId]);
  }

  Future<bool> deleteByPostId(String? postId) {
    return deleteByIndex(r'postId', [postId]);
  }

  bool deleteByPostIdSync(String? postId) {
    return deleteByIndexSync(r'postId', [postId]);
  }

  Future<List<DbPost?>> getAllByPostId(List<String?> postIdValues) {
    final values = postIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'postId', values);
  }

  List<DbPost?> getAllByPostIdSync(List<String?> postIdValues) {
    final values = postIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'postId', values);
  }

  Future<int> deleteAllByPostId(List<String?> postIdValues) {
    final values = postIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'postId', values);
  }

  int deleteAllByPostIdSync(List<String?> postIdValues) {
    final values = postIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'postId', values);
  }

  Future<Id> putByPostId(DbPost object) {
    return putByIndex(r'postId', object);
  }

  Id putByPostIdSync(DbPost object, {bool saveLinks = true}) {
    return putByIndexSync(r'postId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPostId(List<DbPost> objects) {
    return putAllByIndex(r'postId', objects);
  }

  List<Id> putAllByPostIdSync(List<DbPost> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'postId', objects, saveLinks: saveLinks);
  }
}

extension DbPostQueryWhereSort on QueryBuilder<DbPost, DbPost, QWhere> {
  QueryBuilder<DbPost, DbPost, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbPostQueryWhere on QueryBuilder<DbPost, DbPost, QWhereClause> {
  QueryBuilder<DbPost, DbPost, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> postIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'postId',
        value: [null],
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> postIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'postId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> postIdEqualTo(
      String? postId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'postId',
        value: [postId],
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterWhereClause> postIdNotEqualTo(
      String? postId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'postId',
              lower: [],
              upper: [postId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'postId',
              lower: [postId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'postId',
              lower: [postId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'postId',
              lower: [],
              upper: [postId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DbPostQueryFilter on QueryBuilder<DbPost, DbPost, QFilterCondition> {
  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'answer',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'answer',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'answer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'answer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answer',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> answerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'answer',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dislikes',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dislikes',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dislikes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dislikes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dislikes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> dislikesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dislikes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'likes',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'likes',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'likes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'likes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'likes',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> likesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'likes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> mineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mine',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'postId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'postId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'postId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'postId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'postId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> postIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'postId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'promptDateId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'promptDateId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptDateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'promptDateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptDateId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptDateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'promptDateId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'promptId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'promptId',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'promptId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> promptIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'promptId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> seenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seen',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'wins',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'wins',
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wins',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wins',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wins',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterFilterCondition> winsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wins',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbPostQueryObject on QueryBuilder<DbPost, DbPost, QFilterCondition> {}

extension DbPostQueryLinks on QueryBuilder<DbPost, DbPost, QFilterCondition> {}

extension DbPostQuerySortBy on QueryBuilder<DbPost, DbPost, QSortBy> {
  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByAnswer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByAnswerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByDislikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dislikes', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByDislikesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dislikes', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByLikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likes', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByLikesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likes', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByMine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mine', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByMineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mine', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPromptDateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPromptDateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPromptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByPromptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByWins() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wins', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> sortByWinsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wins', Sort.desc);
    });
  }
}

extension DbPostQuerySortThenBy on QueryBuilder<DbPost, DbPost, QSortThenBy> {
  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByAnswer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByAnswerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByDislikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dislikes', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByDislikesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dislikes', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByLikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likes', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByLikesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likes', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByMine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mine', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByMineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mine', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPromptDateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPromptDateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPromptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByPromptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByWins() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wins', Sort.asc);
    });
  }

  QueryBuilder<DbPost, DbPost, QAfterSortBy> thenByWinsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wins', Sort.desc);
    });
  }
}

extension DbPostQueryWhereDistinct on QueryBuilder<DbPost, DbPost, QDistinct> {
  QueryBuilder<DbPost, DbPost, QDistinct> distinctByAnswer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByDislikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dislikes');
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByLikes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'likes');
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByMine() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mine');
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByPostId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByPromptDateId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptDateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByPromptId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seen');
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPost, DbPost, QDistinct> distinctByWins() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wins');
    });
  }
}

extension DbPostQueryProperty on QueryBuilder<DbPost, DbPost, QQueryProperty> {
  QueryBuilder<DbPost, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> answerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answer');
    });
  }

  QueryBuilder<DbPost, int?, QQueryOperations> dislikesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dislikes');
    });
  }

  QueryBuilder<DbPost, int?, QQueryOperations> likesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'likes');
    });
  }

  QueryBuilder<DbPost, bool, QQueryOperations> mineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mine');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> postIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postId');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> promptDateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptDateId');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> promptIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptId');
    });
  }

  QueryBuilder<DbPost, bool, QQueryOperations> seenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seen');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<DbPost, String?, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }

  QueryBuilder<DbPost, int?, QQueryOperations> winsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wins');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetDbPromptCollection on Isar {
  IsarCollection<DbPrompt> get dbPrompts => this.collection();
}

const DbPromptSchema = CollectionSchema(
  name: r'DbPrompt',
  id: -369734858156261406,
  properties: {
    r'after': PropertySchema(
      id: 0,
      name: r'after',
      type: IsarType.string,
    ),
    r'before': PropertySchema(
      id: 1,
      name: r'before',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.string,
    ),
    r'liked': PropertySchema(
      id: 3,
      name: r'liked',
      type: IsarType.long,
    ),
    r'promptDateId': PropertySchema(
      id: 4,
      name: r'promptDateId',
      type: IsarType.string,
    ),
    r'promptId': PropertySchema(
      id: 5,
      name: r'promptId',
      type: IsarType.string,
    ),
    r'responses': PropertySchema(
      id: 6,
      name: r'responses',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _dbPromptEstimateSize,
  serialize: _dbPromptSerialize,
  deserialize: _dbPromptDeserialize,
  deserializeProp: _dbPromptDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbPromptGetId,
  getLinks: _dbPromptGetLinks,
  attach: _dbPromptAttach,
  version: '3.4.1',
);

int _dbPromptEstimateSize(
  DbPrompt object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.after;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.before;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.date;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.promptDateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.promptId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbPromptSerialize(
  DbPrompt object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.after);
  writer.writeString(offsets[1], object.before);
  writer.writeString(offsets[2], object.date);
  writer.writeLong(offsets[3], object.liked);
  writer.writeString(offsets[4], object.promptDateId);
  writer.writeString(offsets[5], object.promptId);
  writer.writeLong(offsets[6], object.responses);
  writer.writeString(offsets[7], object.type);
}

DbPrompt _dbPromptDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbPrompt(
    reader.readStringOrNull(offsets[1]),
    reader.readStringOrNull(offsets[0]),
    reader.readStringOrNull(offsets[4]),
    reader.readStringOrNull(offsets[5]),
    reader.readStringOrNull(offsets[2]),
    reader.readStringOrNull(offsets[7]),
  );
  object.id = id;
  object.liked = reader.readLong(offsets[3]);
  object.responses = reader.readLong(offsets[6]);
  return object;
}

P _dbPromptDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbPromptGetId(DbPrompt object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbPromptGetLinks(DbPrompt object) {
  return [];
}

void _dbPromptAttach(IsarCollection<dynamic> col, Id id, DbPrompt object) {
  object.id = id;
}

extension DbPromptQueryWhereSort on QueryBuilder<DbPrompt, DbPrompt, QWhere> {
  QueryBuilder<DbPrompt, DbPrompt, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbPromptQueryWhere on QueryBuilder<DbPrompt, DbPrompt, QWhereClause> {
  QueryBuilder<DbPrompt, DbPrompt, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbPromptQueryFilter
    on QueryBuilder<DbPrompt, DbPrompt, QFilterCondition> {
  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'after',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'after',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'after',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'after',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'after',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'after',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> afterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'after',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'before',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'before',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'before',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'before',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'before',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'before',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> beforeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'before',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> likedEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'liked',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> likedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'liked',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> likedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'liked',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> likedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'liked',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'promptDateId',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition>
      promptDateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'promptDateId',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition>
      promptDateIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptDateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition>
      promptDateIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'promptDateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptDateIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'promptDateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition>
      promptDateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptDateId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition>
      promptDateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'promptDateId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'promptId',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'promptId',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'promptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'promptId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> promptIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'promptId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> responsesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'responses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> responsesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'responses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> responsesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'responses',
        value: value,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> responsesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'responses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension DbPromptQueryObject
    on QueryBuilder<DbPrompt, DbPrompt, QFilterCondition> {}

extension DbPromptQueryLinks
    on QueryBuilder<DbPrompt, DbPrompt, QFilterCondition> {}

extension DbPromptQuerySortBy on QueryBuilder<DbPrompt, DbPrompt, QSortBy> {
  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'after', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'after', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'before', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'before', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liked', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByLikedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liked', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByPromptDateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByPromptDateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByPromptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByPromptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByResponses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responses', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByResponsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responses', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DbPromptQuerySortThenBy
    on QueryBuilder<DbPrompt, DbPrompt, QSortThenBy> {
  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'after', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'after', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'before', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'before', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liked', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByLikedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liked', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByPromptDateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByPromptDateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptDateId', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByPromptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByPromptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptId', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByResponses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responses', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByResponsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responses', Sort.desc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DbPromptQueryWhereDistinct
    on QueryBuilder<DbPrompt, DbPrompt, QDistinct> {
  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByAfter(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'after', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByBefore(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'before', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByLiked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'liked');
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByPromptDateId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptDateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByPromptId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByResponses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'responses');
    });
  }

  QueryBuilder<DbPrompt, DbPrompt, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension DbPromptQueryProperty
    on QueryBuilder<DbPrompt, DbPrompt, QQueryProperty> {
  QueryBuilder<DbPrompt, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> afterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'after');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> beforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'before');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DbPrompt, int, QQueryOperations> likedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'liked');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> promptDateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptDateId');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> promptIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptId');
    });
  }

  QueryBuilder<DbPrompt, int, QQueryOperations> responsesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'responses');
    });
  }

  QueryBuilder<DbPrompt, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetDbUserCollection on Isar {
  IsarCollection<DbUser> get dbUsers => this.collection();
}

const DbUserSchema = CollectionSchema(
  name: r'DbUser',
  id: -9131662857584035194,
  properties: {
    r'friend': PropertySchema(
      id: 0,
      name: r'friend',
      type: IsarType.bool,
    ),
    r'friends': PropertySchema(
      id: 1,
      name: r'friends',
      type: IsarType.stringList,
    ),
    r'isCurrentUser': PropertySchema(
      id: 2,
      name: r'isCurrentUser',
      type: IsarType.bool,
    ),
    r'numFriends': PropertySchema(
      id: 3,
      name: r'numFriends',
      type: IsarType.long,
    ),
    r'numPendingFriends': PropertySchema(
      id: 4,
      name: r'numPendingFriends',
      type: IsarType.long,
    ),
    r'numPosts': PropertySchema(
      id: 5,
      name: r'numPosts',
      type: IsarType.long,
    ),
    r'pendingFriend': PropertySchema(
      id: 6,
      name: r'pendingFriend',
      type: IsarType.bool,
    ),
    r'pendingFriends': PropertySchema(
      id: 7,
      name: r'pendingFriends',
      type: IsarType.stringList,
    ),
    r'profilePicture': PropertySchema(
      id: 8,
      name: r'profilePicture',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 9,
      name: r'uid',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 10,
      name: r'username',
      type: IsarType.string,
    )
  },
  estimateSize: _dbUserEstimateSize,
  serialize: _dbUserSerialize,
  deserialize: _dbUserDeserialize,
  deserializeProp: _dbUserDeserializeProp,
  idName: r'id',
  indexes: {
    r'username': IndexSchema(
      id: -2899563114555695793,
      name: r'username',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'username',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dbUserGetId,
  getLinks: _dbUserGetLinks,
  attach: _dbUserAttach,
  version: '3.4.1',
);

int _dbUserEstimateSize(
  DbUser object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.friends.length * 3;
  {
    for (var i = 0; i < object.friends.length; i++) {
      final value = object.friends[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.pendingFriends.length * 3;
  {
    for (var i = 0; i < object.pendingFriends.length; i++) {
      final value = object.pendingFriends[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.profilePicture.length * 3;
  {
    final value = object.uid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.username;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbUserSerialize(
  DbUser object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.friend);
  writer.writeStringList(offsets[1], object.friends);
  writer.writeBool(offsets[2], object.isCurrentUser);
  writer.writeLong(offsets[3], object.numFriends);
  writer.writeLong(offsets[4], object.numPendingFriends);
  writer.writeLong(offsets[5], object.numPosts);
  writer.writeBool(offsets[6], object.pendingFriend);
  writer.writeStringList(offsets[7], object.pendingFriends);
  writer.writeString(offsets[8], object.profilePicture);
  writer.writeString(offsets[9], object.uid);
  writer.writeString(offsets[10], object.username);
}

DbUser _dbUserDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbUser(
    reader.readStringOrNull(offsets[9]),
    reader.readStringOrNull(offsets[10]),
    reader.readLongOrNull(offsets[3]),
    reader.readLongOrNull(offsets[5]),
    reader.readString(offsets[8]),
  );
  object.friend = reader.readBool(offsets[0]);
  object.friends = reader.readStringList(offsets[1]) ?? [];
  object.id = id;
  object.isCurrentUser = reader.readBool(offsets[2]);
  object.numPendingFriends = reader.readLongOrNull(offsets[4]);
  object.pendingFriend = reader.readBool(offsets[6]);
  object.pendingFriends = reader.readStringList(offsets[7]) ?? [];
  return object;
}

P _dbUserDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbUserGetId(DbUser object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbUserGetLinks(DbUser object) {
  return [];
}

void _dbUserAttach(IsarCollection<dynamic> col, Id id, DbUser object) {
  object.id = id;
}

extension DbUserByIndex on IsarCollection<DbUser> {
  Future<DbUser?> getByUsername(String? username) {
    return getByIndex(r'username', [username]);
  }

  DbUser? getByUsernameSync(String? username) {
    return getByIndexSync(r'username', [username]);
  }

  Future<bool> deleteByUsername(String? username) {
    return deleteByIndex(r'username', [username]);
  }

  bool deleteByUsernameSync(String? username) {
    return deleteByIndexSync(r'username', [username]);
  }

  Future<List<DbUser?>> getAllByUsername(List<String?> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndex(r'username', values);
  }

  List<DbUser?> getAllByUsernameSync(List<String?> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'username', values);
  }

  Future<int> deleteAllByUsername(List<String?> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'username', values);
  }

  int deleteAllByUsernameSync(List<String?> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'username', values);
  }

  Future<Id> putByUsername(DbUser object) {
    return putByIndex(r'username', object);
  }

  Id putByUsernameSync(DbUser object, {bool saveLinks = true}) {
    return putByIndexSync(r'username', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUsername(List<DbUser> objects) {
    return putAllByIndex(r'username', objects);
  }

  List<Id> putAllByUsernameSync(List<DbUser> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'username', objects, saveLinks: saveLinks);
  }

  Future<DbUser?> getByUid(String? uid) {
    return getByIndex(r'uid', [uid]);
  }

  DbUser? getByUidSync(String? uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String? uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String? uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<DbUser?>> getAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<DbUser?> getAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(DbUser object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(DbUser object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<DbUser> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<DbUser> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension DbUserQueryWhereSort on QueryBuilder<DbUser, DbUser, QWhere> {
  QueryBuilder<DbUser, DbUser, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbUserQueryWhere on QueryBuilder<DbUser, DbUser, QWhereClause> {
  QueryBuilder<DbUser, DbUser, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> usernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'username',
        value: [null],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> usernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'username',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> usernameEqualTo(
      String? username) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'username',
        value: [username],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> usernameNotEqualTo(
      String? username) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [null],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> uidEqualTo(String? uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterWhereClause> uidNotEqualTo(String? uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DbUserQueryFilter on QueryBuilder<DbUser, DbUser, QFilterCondition> {
  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'friend',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'friends',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'friends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'friends',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'friends',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      friendsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'friends',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> friendsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'friends',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> isCurrentUserEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCurrentUser',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numFriends',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numFriends',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numFriendsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numFriends',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      numPendingFriendsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numPendingFriends',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      numPendingFriendsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numPendingFriends',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPendingFriendsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numPendingFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      numPendingFriendsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numPendingFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPendingFriendsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numPendingFriends',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPendingFriendsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numPendingFriends',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numPosts',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numPosts',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numPosts',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numPosts',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numPosts',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> numPostsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numPosts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> pendingFriendEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingFriend',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingFriends',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pendingFriends',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pendingFriends',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingFriends',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pendingFriends',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> pendingFriendsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      pendingFriendsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pendingFriends',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profilePicture',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profilePicture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profilePicture',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> profilePictureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profilePicture',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition>
      profilePictureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profilePicture',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterFilterCondition> usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }
}

extension DbUserQueryObject on QueryBuilder<DbUser, DbUser, QFilterCondition> {}

extension DbUserQueryLinks on QueryBuilder<DbUser, DbUser, QFilterCondition> {}

extension DbUserQuerySortBy on QueryBuilder<DbUser, DbUser, QSortBy> {
  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'friend', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByFriendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'friend', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByIsCurrentUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrentUser', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByIsCurrentUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrentUser', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numFriends', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumFriendsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numFriends', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumPendingFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPendingFriends', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumPendingFriendsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPendingFriends', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumPosts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPosts', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByNumPostsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPosts', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByPendingFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingFriend', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByPendingFriendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingFriend', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByProfilePicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePicture', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByProfilePictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePicture', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension DbUserQuerySortThenBy on QueryBuilder<DbUser, DbUser, QSortThenBy> {
  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'friend', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByFriendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'friend', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByIsCurrentUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrentUser', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByIsCurrentUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrentUser', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numFriends', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumFriendsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numFriends', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumPendingFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPendingFriends', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumPendingFriendsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPendingFriends', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumPosts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPosts', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByNumPostsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPosts', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByPendingFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingFriend', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByPendingFriendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingFriend', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByProfilePicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePicture', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByProfilePictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePicture', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbUser, DbUser, QAfterSortBy> thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension DbUserQueryWhereDistinct on QueryBuilder<DbUser, DbUser, QDistinct> {
  QueryBuilder<DbUser, DbUser, QDistinct> distinctByFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'friend');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'friends');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByIsCurrentUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCurrentUser');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByNumFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numFriends');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByNumPendingFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numPendingFriends');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByNumPosts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numPosts');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByPendingFriend() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingFriend');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByPendingFriends() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingFriends');
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByProfilePicture(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profilePicture',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUser, DbUser, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension DbUserQueryProperty on QueryBuilder<DbUser, DbUser, QQueryProperty> {
  QueryBuilder<DbUser, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbUser, bool, QQueryOperations> friendProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'friend');
    });
  }

  QueryBuilder<DbUser, List<String>, QQueryOperations> friendsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'friends');
    });
  }

  QueryBuilder<DbUser, bool, QQueryOperations> isCurrentUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCurrentUser');
    });
  }

  QueryBuilder<DbUser, int?, QQueryOperations> numFriendsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numFriends');
    });
  }

  QueryBuilder<DbUser, int?, QQueryOperations> numPendingFriendsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numPendingFriends');
    });
  }

  QueryBuilder<DbUser, int?, QQueryOperations> numPostsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numPosts');
    });
  }

  QueryBuilder<DbUser, bool, QQueryOperations> pendingFriendProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingFriend');
    });
  }

  QueryBuilder<DbUser, List<String>, QQueryOperations>
      pendingFriendsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingFriends');
    });
  }

  QueryBuilder<DbUser, String, QQueryOperations> profilePictureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profilePicture');
    });
  }

  QueryBuilder<DbUser, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<DbUser, String?, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetDbCommentCollection on Isar {
  IsarCollection<DbComment> get dbComments => this.collection();
}

const DbCommentSchema = CollectionSchema(
  name: r'DbComment',
  id: -9052731186466062930,
  properties: {
    r'comment': PropertySchema(
      id: 0,
      name: r'comment',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 1,
      name: r'username',
      type: IsarType.string,
    )
  },
  estimateSize: _dbCommentEstimateSize,
  serialize: _dbCommentSerialize,
  deserialize: _dbCommentDeserialize,
  deserializeProp: _dbCommentDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbCommentGetId,
  getLinks: _dbCommentGetLinks,
  attach: _dbCommentAttach,
  version: '3.4.1',
);

int _dbCommentEstimateSize(
  DbComment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.comment;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.username;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbCommentSerialize(
  DbComment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.comment);
  writer.writeString(offsets[1], object.username);
}

DbComment _dbCommentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbComment(
    reader.readStringOrNull(offsets[1]),
    reader.readStringOrNull(offsets[0]),
  );
  object.id = id;
  return object;
}

P _dbCommentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbCommentGetId(DbComment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbCommentGetLinks(DbComment object) {
  return [];
}

void _dbCommentAttach(IsarCollection<dynamic> col, Id id, DbComment object) {
  object.id = id;
}

extension DbCommentQueryWhereSort
    on QueryBuilder<DbComment, DbComment, QWhere> {
  QueryBuilder<DbComment, DbComment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbCommentQueryWhere
    on QueryBuilder<DbComment, DbComment, QWhereClause> {
  QueryBuilder<DbComment, DbComment, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbCommentQueryFilter
    on QueryBuilder<DbComment, DbComment, QFilterCondition> {
  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'comment',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'comment',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'comment',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'comment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'comment',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> commentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'comment',
        value: '',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition>
      commentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'comment',
        value: '',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition>
      usernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'username',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition> usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }
}

extension DbCommentQueryObject
    on QueryBuilder<DbComment, DbComment, QFilterCondition> {}

extension DbCommentQueryLinks
    on QueryBuilder<DbComment, DbComment, QFilterCondition> {}

extension DbCommentQuerySortBy on QueryBuilder<DbComment, DbComment, QSortBy> {
  QueryBuilder<DbComment, DbComment, QAfterSortBy> sortByComment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comment', Sort.asc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> sortByCommentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comment', Sort.desc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension DbCommentQuerySortThenBy
    on QueryBuilder<DbComment, DbComment, QSortThenBy> {
  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenByComment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comment', Sort.asc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenByCommentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comment', Sort.desc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<DbComment, DbComment, QAfterSortBy> thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension DbCommentQueryWhereDistinct
    on QueryBuilder<DbComment, DbComment, QDistinct> {
  QueryBuilder<DbComment, DbComment, QDistinct> distinctByComment(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'comment', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbComment, DbComment, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension DbCommentQueryProperty
    on QueryBuilder<DbComment, DbComment, QQueryProperty> {
  QueryBuilder<DbComment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbComment, String?, QQueryOperations> commentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'comment');
    });
  }

  QueryBuilder<DbComment, String?, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetDbNotificationCollection on Isar {
  IsarCollection<DbNotification> get dbNotifications => this.collection();
}

const DbNotificationSchema = CollectionSchema(
  name: r'DbNotification',
  id: 4060669196296592869,
  properties: {
    r'by': PropertySchema(
      id: 0,
      name: r'by',
      type: IsarType.string,
    ),
    r'day': PropertySchema(
      id: 1,
      name: r'day',
      type: IsarType.string,
    ),
    r'notification': PropertySchema(
      id: 2,
      name: r'notification',
      type: IsarType.string,
    ),
    r'seen': PropertySchema(
      id: 3,
      name: r'seen',
      type: IsarType.bool,
    )
  },
  estimateSize: _dbNotificationEstimateSize,
  serialize: _dbNotificationSerialize,
  deserialize: _dbNotificationDeserialize,
  deserializeProp: _dbNotificationDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbNotificationGetId,
  getLinks: _dbNotificationGetLinks,
  attach: _dbNotificationAttach,
  version: '3.4.1',
);

int _dbNotificationEstimateSize(
  DbNotification object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.by;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.day;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notification;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbNotificationSerialize(
  DbNotification object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.by);
  writer.writeString(offsets[1], object.day);
  writer.writeString(offsets[2], object.notification);
  writer.writeBool(offsets[3], object.seen);
}

DbNotification _dbNotificationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbNotification(
    reader.readStringOrNull(offsets[2]),
    reader.readStringOrNull(offsets[0]),
    reader.readStringOrNull(offsets[1]),
  );
  object.id = id;
  object.seen = reader.readBool(offsets[3]);
  return object;
}

P _dbNotificationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbNotificationGetId(DbNotification object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbNotificationGetLinks(DbNotification object) {
  return [];
}

void _dbNotificationAttach(
    IsarCollection<dynamic> col, Id id, DbNotification object) {
  object.id = id;
}

extension DbNotificationQueryWhereSort
    on QueryBuilder<DbNotification, DbNotification, QWhere> {
  QueryBuilder<DbNotification, DbNotification, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbNotificationQueryWhere
    on QueryBuilder<DbNotification, DbNotification, QWhereClause> {
  QueryBuilder<DbNotification, DbNotification, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbNotificationQueryFilter
    on QueryBuilder<DbNotification, DbNotification, QFilterCondition> {
  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'by',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'by',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition> byEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition> byBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'by',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'by',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition> byMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'by',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'by',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      byIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'by',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'day',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'day',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'day',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'day',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'day',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'day',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      dayIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'day',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notification',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notification',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notification',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notification',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notification',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notification',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      notificationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notification',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterFilterCondition>
      seenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seen',
        value: value,
      ));
    });
  }
}

extension DbNotificationQueryObject
    on QueryBuilder<DbNotification, DbNotification, QFilterCondition> {}

extension DbNotificationQueryLinks
    on QueryBuilder<DbNotification, DbNotification, QFilterCondition> {}

extension DbNotificationQuerySortBy
    on QueryBuilder<DbNotification, DbNotification, QSortBy> {
  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortByBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'by', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortByByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'by', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy>
      sortByNotification() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notification', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy>
      sortByNotificationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notification', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> sortBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }
}

extension DbNotificationQuerySortThenBy
    on QueryBuilder<DbNotification, DbNotification, QSortThenBy> {
  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenByBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'by', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenByByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'by', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy>
      thenByNotification() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notification', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy>
      thenByNotificationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notification', Sort.desc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QAfterSortBy> thenBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }
}

extension DbNotificationQueryWhereDistinct
    on QueryBuilder<DbNotification, DbNotification, QDistinct> {
  QueryBuilder<DbNotification, DbNotification, QDistinct> distinctByBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'by', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QDistinct> distinctByDay(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'day', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QDistinct>
      distinctByNotification({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notification', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbNotification, DbNotification, QDistinct> distinctBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seen');
    });
  }
}

extension DbNotificationQueryProperty
    on QueryBuilder<DbNotification, DbNotification, QQueryProperty> {
  QueryBuilder<DbNotification, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbNotification, String?, QQueryOperations> byProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'by');
    });
  }

  QueryBuilder<DbNotification, String?, QQueryOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'day');
    });
  }

  QueryBuilder<DbNotification, String?, QQueryOperations>
      notificationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notification');
    });
  }

  QueryBuilder<DbNotification, bool, QQueryOperations> seenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seen');
    });
  }
}
