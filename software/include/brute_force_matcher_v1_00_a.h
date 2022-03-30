#ifndef __BRUTE_FORCE_MATCHER_V1_00_A_H__
#define __BRUTE_FORCE_MATCHER_V1_00_A_H__

#define DESC_SIZE		64
#define BUS_SIZE		16
#define NUM_FRAC_BITS	14
#define NUM_ENGINES		2
#define MESSAGE_LENGTH	(3 + NUM_ENGINES)
#define MAX_MODEL_KP	2048

#include "soc_it_adapter.h"
#include <algorithm>

template <typename DType>
struct keypoint_t {
	uint32_t laplacian;
	uint32_t scale;
	uint16_t id;
	uint16_t cell_id;
	uint16_t y;
	uint16_t x;
	DType descriptors[DESC_SIZE];
};

typedef struct {
	float first_score;
	uint16_t first_model_id;
	uint16_t first_query_id;
	float second_score;
	uint16_t second_model_id;
	uint16_t second_query_id;
}matchTable_t;

typedef struct {
	uint16_t cellID;
	uint16_t numMatches;
}matchTableInfoOutput_t;

typedef struct __reg128 {
	uint64_t lower;
	uint64_t upper;
}_uint128_t;

typedef struct {
	uint64_t addr;
	uint32_t count;
	uint16_t cellID;
	uint16_t padding;
} cell_info_table;

typedef struct {
	SocItHandle *matchTable = NULL;
	SocItHandle *modelData = NULL;
	SocItHandle *cellData = NULL;
	SocItHandle *matchTableInfoOutput = NULL;
}surf_data_t;

// OpenCV
#ifdef USE_OPENCV
#include "opencv2/opencv.hpp" 
#include "opencv2/core.hpp"
#include "opencv2/highgui.hpp"
#include "opencv2/xfeatures2d/cuda.hpp"
#include "opencv2/cudafeatures2d.hpp"
#include "opencv2/core.hpp"
#include "opencv2/features2d.hpp"
#include "opencv2/xfeatures2d.hpp"
#include "opencv2/highgui.hpp"
#include "opencv2/xfeatures2d/nonfree.hpp"
#include "opencv2/xfeatures2d/cuda.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/photo/cuda.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/imgproc/imgproc_c.h"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/core.hpp"
#include "opencv2/features2d.hpp"
#include "opencv2/highgui.hpp"
#include "opencv2/cudafeatures2d.hpp"
#include "opencv2/xfeatures2d/cuda.hpp"
#include "opencv2/imgcodecs.hpp"
#endif

class brute_force_matcher_v1_00_a {

	public:
		brute_force_matcher_v1_00_a(string identifier, uint8_t bus_id, uint8_t switch_id, uint8_t port_id, SocItAdapter* adapter);
		~brute_force_matcher_v1_00_a(void);

		string GetName();
		void Reset();
		void Process(uint64_t modelData_addr, uint64_t modelData_length, uint64_t cellData_addr, uint64_t cellData_length, SocItHandle **matchTable, SocItHandle **matchTableInfo, int numCellsX = 1, int numCellsY = 1, bool wr_matchTbale_info = false);
#ifdef USE_OPENCV		
		void Process(cv::Mat query, cv::Mat train, std::vector<std::vector<cv::DMatch>> &matches, SocItHandle **matchTableInfo = NULL, int numCellsX = 1, int numCellsY = 1, bool wr_matchTbale_info = false);
		void Process(std::vector<float> query, std::vector<float> train, std::vector<std::vector<cv::DMatch>> &matches, SocItHandle **matchTableInfo = NULL, int numCellsX = 1, int numCellsY = 1, bool wr_matchTbale_info = false);
		void dataTransform(cv::Mat descriptor_in, SocItHandle **kp_desc_out);
		void dataTransform(std::vector<float> descriptor_in, SocItHandle **kp_desc_out);
		void dataTransform(SocItHandle *matches_in, int num_matches_in, std::vector<std::vector<cv::DMatch>> &matches_out);
#endif		
		void coalesceMatches(int numMatches, SocItHandle **matchTable_in, int numIterations, SocItHandle **matchTable_out, int *stride);

	protected:

	private:
		string m_Name;

		bool m_IsConfigured;
	
		SocItAdapter* m_SocItAdapter;
		SocItAddress m_DeviceAddress;
	
		SocItAdapter* get_soc_it_adapter();
		void set_soc_it_adapter(SocItAdapter* adapter);

		SocItAddress GetDeviceAddress();
		void SetDeviceAddress(uint8_t bus_id, uint8_t switch_id, uint8_t port_id);

	
};

#endif
