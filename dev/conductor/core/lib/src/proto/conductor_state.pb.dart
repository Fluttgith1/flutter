// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
//  Generated code. Do not modify.
//  source: conductor_state.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'conductor_state.pbenum.dart';

export 'conductor_state.pbenum.dart';

class Remote extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Remote',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'url')
    ..hasRequiredFields = false;

  Remote._() : super();
  factory Remote({
    $core.String? name,
    $core.String? url,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (url != null) {
      _result.url = url;
    }
    return _result;
  }
  factory Remote.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Remote.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Remote clone() => Remote()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Remote copyWith(void Function(Remote) updates) =>
      super.copyWith((message) => updates(message as Remote)) as Remote; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Remote create() => Remote._();
  Remote createEmptyInstance() => create();
  static $pb.PbList<Remote> createRepeated() => $pb.PbList<Remote>();
  @$core.pragma('dart2js:noInline')
  static Remote getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Remote>(create);
  static Remote? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => clearField(2);
}

class Repository extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Repository',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'candidateBranch',
        protoName: 'candidateBranch')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startingGitHead',
        protoName: 'startingGitHead')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentGitHead',
        protoName: 'currentGitHead')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'checkoutPath',
        protoName: 'checkoutPath')
    ..aOM<Remote>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'upstream',
        subBuilder: Remote.create)
    ..aOM<Remote>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mirror',
        subBuilder: Remote.create)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dartRevision',
        protoName: 'dartRevision')
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workingBranch',
        protoName: 'workingBranch')
    ..hasRequiredFields = false;

  Repository._() : super();
  factory Repository({
    $core.String? candidateBranch,
    $core.String? startingGitHead,
    $core.String? currentGitHead,
    $core.String? checkoutPath,
    Remote? upstream,
    Remote? mirror,
    $core.String? dartRevision,
    $core.String? workingBranch,
  }) {
    final _result = create();
    if (candidateBranch != null) {
      _result.candidateBranch = candidateBranch;
    }
    if (startingGitHead != null) {
      _result.startingGitHead = startingGitHead;
    }
    if (currentGitHead != null) {
      _result.currentGitHead = currentGitHead;
    }
    if (checkoutPath != null) {
      _result.checkoutPath = checkoutPath;
    }
    if (upstream != null) {
      _result.upstream = upstream;
    }
    if (mirror != null) {
      _result.mirror = mirror;
    }
    if (dartRevision != null) {
      _result.dartRevision = dartRevision;
    }
    if (workingBranch != null) {
      _result.workingBranch = workingBranch;
    }
    return _result;
  }
  factory Repository.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Repository.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Repository clone() => Repository()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Repository copyWith(void Function(Repository) updates) =>
      super.copyWith((message) => updates(message as Repository)) as Repository; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Repository create() => Repository._();
  Repository createEmptyInstance() => create();
  static $pb.PbList<Repository> createRepeated() => $pb.PbList<Repository>();
  @$core.pragma('dart2js:noInline')
  static Repository getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Repository>(create);
  static Repository? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidateBranch => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidateBranch($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCandidateBranch() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateBranch() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get startingGitHead => $_getSZ(1);
  @$pb.TagNumber(2)
  set startingGitHead($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStartingGitHead() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartingGitHead() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get currentGitHead => $_getSZ(2);
  @$pb.TagNumber(3)
  set currentGitHead($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCurrentGitHead() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentGitHead() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get checkoutPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set checkoutPath($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCheckoutPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearCheckoutPath() => clearField(4);

  @$pb.TagNumber(5)
  Remote get upstream => $_getN(4);
  @$pb.TagNumber(5)
  set upstream(Remote v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasUpstream() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpstream() => clearField(5);
  @$pb.TagNumber(5)
  Remote ensureUpstream() => $_ensure(4);

  @$pb.TagNumber(6)
  Remote get mirror => $_getN(5);
  @$pb.TagNumber(6)
  set mirror(Remote v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasMirror() => $_has(5);
  @$pb.TagNumber(6)
  void clearMirror() => clearField(6);
  @$pb.TagNumber(6)
  Remote ensureMirror() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get dartRevision => $_getSZ(6);
  @$pb.TagNumber(7)
  set dartRevision($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDartRevision() => $_has(6);
  @$pb.TagNumber(7)
  void clearDartRevision() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get workingBranch => $_getSZ(7);
  @$pb.TagNumber(8)
  set workingBranch($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasWorkingBranch() => $_has(7);
  @$pb.TagNumber(8)
  void clearWorkingBranch() => clearField(8);
}

class ConductorState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConductorState',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'conductor_state'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseChannel',
        protoName: 'releaseChannel')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseVersion',
        protoName: 'releaseVersion')
    ..aOM<Repository>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'engine',
        subBuilder: Repository.create)
    ..aOM<Repository>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'framework',
        subBuilder: Repository.create)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdDate',
        protoName: 'createdDate')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastUpdatedDate',
        protoName: 'lastUpdatedDate')
    ..pPS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logs')
    ..e<ReleasePhase>(
        8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentPhase', $pb.PbFieldType.OE,
        protoName: 'currentPhase',
        defaultOrMaker: ReleasePhase.APPLY_ENGINE_CHERRYPICKS,
        valueOf: ReleasePhase.valueOf,
        enumValues: ReleasePhase.values)
    ..aOS(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conductorVersion',
        protoName: 'conductorVersion')
    ..e<ReleaseType>(
        11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'releaseType', $pb.PbFieldType.OE,
        protoName: 'releaseType',
        defaultOrMaker: ReleaseType.STABLE_INITIAL,
        valueOf: ReleaseType.valueOf,
        enumValues: ReleaseType.values)
    ..hasRequiredFields = false;

  ConductorState._() : super();
  factory ConductorState({
    $core.String? releaseChannel,
    $core.String? releaseVersion,
    Repository? engine,
    Repository? framework,
    $fixnum.Int64? createdDate,
    $fixnum.Int64? lastUpdatedDate,
    $core.Iterable<$core.String>? logs,
    ReleasePhase? currentPhase,
    $core.String? conductorVersion,
    ReleaseType? releaseType,
  }) {
    final _result = create();
    if (releaseChannel != null) {
      _result.releaseChannel = releaseChannel;
    }
    if (releaseVersion != null) {
      _result.releaseVersion = releaseVersion;
    }
    if (engine != null) {
      _result.engine = engine;
    }
    if (framework != null) {
      _result.framework = framework;
    }
    if (createdDate != null) {
      _result.createdDate = createdDate;
    }
    if (lastUpdatedDate != null) {
      _result.lastUpdatedDate = lastUpdatedDate;
    }
    if (logs != null) {
      _result.logs.addAll(logs);
    }
    if (currentPhase != null) {
      _result.currentPhase = currentPhase;
    }
    if (conductorVersion != null) {
      _result.conductorVersion = conductorVersion;
    }
    if (releaseType != null) {
      _result.releaseType = releaseType;
    }
    return _result;
  }
  factory ConductorState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConductorState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConductorState clone() => ConductorState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConductorState copyWith(void Function(ConductorState) updates) =>
      super.copyWith((message) => updates(message as ConductorState))
          as ConductorState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConductorState create() => ConductorState._();
  ConductorState createEmptyInstance() => create();
  static $pb.PbList<ConductorState> createRepeated() => $pb.PbList<ConductorState>();
  @$core.pragma('dart2js:noInline')
  static ConductorState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConductorState>(create);
  static ConductorState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get releaseChannel => $_getSZ(0);
  @$pb.TagNumber(1)
  set releaseChannel($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasReleaseChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearReleaseChannel() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get releaseVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set releaseVersion($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasReleaseVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearReleaseVersion() => clearField(2);

  @$pb.TagNumber(3)
  Repository get engine => $_getN(2);
  @$pb.TagNumber(3)
  set engine(Repository v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEngine() => $_has(2);
  @$pb.TagNumber(3)
  void clearEngine() => clearField(3);
  @$pb.TagNumber(3)
  Repository ensureEngine() => $_ensure(2);

  @$pb.TagNumber(4)
  Repository get framework => $_getN(3);
  @$pb.TagNumber(4)
  set framework(Repository v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasFramework() => $_has(3);
  @$pb.TagNumber(4)
  void clearFramework() => clearField(4);
  @$pb.TagNumber(4)
  Repository ensureFramework() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdDate => $_getI64(4);
  @$pb.TagNumber(5)
  set createdDate($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCreatedDate() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedDate() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get lastUpdatedDate => $_getI64(5);
  @$pb.TagNumber(6)
  set lastUpdatedDate($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasLastUpdatedDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastUpdatedDate() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.String> get logs => $_getList(6);

  @$pb.TagNumber(8)
  ReleasePhase get currentPhase => $_getN(7);
  @$pb.TagNumber(8)
  set currentPhase(ReleasePhase v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasCurrentPhase() => $_has(7);
  @$pb.TagNumber(8)
  void clearCurrentPhase() => clearField(8);

  @$pb.TagNumber(10)
  $core.String get conductorVersion => $_getSZ(8);
  @$pb.TagNumber(10)
  set conductorVersion($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasConductorVersion() => $_has(8);
  @$pb.TagNumber(10)
  void clearConductorVersion() => clearField(10);

  @$pb.TagNumber(11)
  ReleaseType get releaseType => $_getN(9);
  @$pb.TagNumber(11)
  set releaseType(ReleaseType v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasReleaseType() => $_has(9);
  @$pb.TagNumber(11)
  void clearReleaseType() => clearField(11);
}
