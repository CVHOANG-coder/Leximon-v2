import '../../core/network/api_client.dart';
import '../models/iap_packages_response.dart';

class IapPackageApiService {
  IapPackageApiService({required this.apiClient});

  static const packagesPath = '/iap/packages';

  final ApiClient apiClient;

  Future<IapPackagesResponse> getPackages({required String platform}) async {
    final response = await apiClient.get(
      packagesPath,
      queryParameters: {'platform': platform},
    );
    return IapPackagesResponse.fromApiResponse(response);
  }
}
