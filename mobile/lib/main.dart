import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/ingredient_checker/repository/halal_repository.dart';

void main() {
  runApp(HalalAssistantApp(repository: HalalRepository(ApiClient())));
}
