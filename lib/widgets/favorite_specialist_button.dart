import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_portfolio_service.dart';

/// Виджет кнопки добавления/удаления специалиста из избранного
class FavoriteSpecialistButton extends StatefulWidget {
  const FavoriteSpecialistButton({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.onFavoriteChanged,
    this.showText = true,
    this.size,
  });
  final String specialistId;
  final String specialistName;
  final VoidCallback? onFavoriteChanged;
  final bool showText;
  final double? size;

  @override
  State<FavoriteSpecialistButton> createState() => _FavoriteSpecialistButtonState();
}

class _FavoriteSpecialistButtonState extends State<FavoriteSpecialistButton> {
  final CustomerPortfolioService _portfolioService = CustomerPortfolioService();
  final AuthService _authService = AuthService();

  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final currentUser = _authService.currentUser;

    try {
      final isFavorite = await _portfolioService.isFavoriteSpecialist(
        currentUser.uid,
        widget.specialistId,
      );

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      debugPrint('Ошибка проверки статуса избранного: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = _authService.currentUser;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _portfolioService.removeFromFavorites(
          currentUser.uid,
          widget.specialistId,
        );
        _showSnackBar('${widget.specialistName} удален из избранного');
      } else {
        await _portfolioService.addToFavorites(
          currentUser.uid,
          widget.specialistId,
        );
        _showSnackBar('${widget.specialistName} добавлен в избранное');
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      widget.onFavoriteChanged?.call();
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAuthError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Необходимо войти в систему'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _isLoading ? null : _toggleFavorite,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isFavorite ? Colors.red : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isFavorite ? Colors.red : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: widget.size ?? 16,
                  height: widget.size ?? 16,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.white : Colors.grey[600],
                  size: widget.size ?? 16,
                ),
              if (widget.showText) ...[
                const SizedBox(width: 6),
                Text(
                  _isFavorite ? 'В избранном' : 'В избранное',
                  style: TextStyle(
                    color: _isFavorite ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Компактная версия кнопки избранного (только иконка)
class FavoriteSpecialistIconButton extends StatelessWidget {
  const FavoriteSpecialistIconButton({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.onFavoriteChanged,
    this.size,
  });
  final String specialistId;
  final String specialistName;
  final VoidCallback? onFavoriteChanged;
  final double? size;

  @override
  Widget build(BuildContext context) => FavoriteSpecialistButton(
        specialistId: specialistId,
        specialistName: specialistName,
        onFavoriteChanged: onFavoriteChanged,
        showText: false,
        size: size,
      );
}

/// Плавающая кнопка избранного
class FloatingFavoriteButton extends StatelessWidget {
  const FloatingFavoriteButton({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.onFavoriteChanged,
  });
  final String specialistId;
  final String specialistName;
  final VoidCallback? onFavoriteChanged;

  @override
  Widget build(BuildContext context) => Positioned(
        top: 16,
        right: 16,
        child: FavoriteSpecialistIconButton(
          specialistId: specialistId,
          specialistName: specialistName,
          onFavoriteChanged: onFavoriteChanged,
          size: 20,
        ),
      );
}
