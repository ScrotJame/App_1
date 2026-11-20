import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/user_sesion.dart';
import '../data/daily_review_repository.dart';
import '../data/daily_review_status.dart';

/// Rebuilds with today's review status. Only reads: never creates a review.
class DailyReviewStatusBuilder extends StatefulWidget {
  const DailyReviewStatusBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, DailyReviewStatus status) builder;

  @override
  State<DailyReviewStatusBuilder> createState() =>
      _DailyReviewStatusBuilderState();
}

class _DailyReviewStatusBuilderState extends State<DailyReviewStatusBuilder> {
  late final Stream<DailyReviewStatus> _status;

  @override
  void initState() {
    super.initState();
    _status = context
        .read<DailyReviewRepository>()
        .watchTodayStatus(UserSession.instance.userKey);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DailyReviewStatus>(
      stream: _status,
      initialData: DailyReviewStatus.notCreated,
      builder: (context, snapshot) => widget.builder(
        context,
        snapshot.data ?? DailyReviewStatus.notCreated,
      ),
    );
  }
}
