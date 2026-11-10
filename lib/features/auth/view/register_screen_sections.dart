part of 'register_screen.dart';

extension _RegisterScreenStateSections1 on _RegisterScreenState {
  void _register() {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signUp(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _pass.text,
      referralCode: _ref.text,
      zoneId: _zone?.id,
    );
  }

  Widget _errorText() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.message != c.message || p.status != c.status,
      builder: (context, s) {
        if (s.status != AuthStatus.error || s.message == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(s.message!, style: AppText.body(12, color: AppColors.danger)),
        );
      },
    );
  }

  Widget _button() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.isBusy != c.isBusy,
      builder: (context, s) => Pressable(
        onTap: s.isBusy ? null : _register,
        child: Container(
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          child: s.isBusy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                )
              : Text('أنشئ حساب', style: AppText.h(15, color: AppColors.white)),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('عندك حساب بالفعل؟ ', style: AppText.body(12, color: AppColors.white.withValues(alpha: 0.7))),
            Pressable(
              onTap: context.read<AppNavCubit>().goLogin,
              child: Text('سجّل دخول', style: AppText.h(13, color: AppColors.accent400)),
            ),
          ],
        ),
      ),
    );
  }
}
