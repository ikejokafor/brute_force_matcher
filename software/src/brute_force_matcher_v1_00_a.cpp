#include <cmath>
#include <string>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <thread>
#include <mutex>

#include "brute_force_matcher_v1_00_a.h"
#include "soc_it_message.h"
#include "image_descriptor.h"


int nextMultiple4(int value) {
	if (value % 4 == 0) {
		return value;
	}
	else {
		return (((value / 4) + 1) * 4);
	}
}

brute_force_matcher_v1_00_a::brute_force_matcher_v1_00_a(string identifier, uint8_t bus_id, uint8_t switch_id, uint8_t port_id, SocItAdapter* adapter)
{
	m_Name = identifier;

	m_IsConfigured = true;

	set_soc_it_adapter(adapter);
	SetDeviceAddress(bus_id, switch_id, port_id);

    cout << "[BRUTE FORCE MATCHER]: Accelerator Handle Initialized with " << NUM_ENGINES << " Engines" << endl;
}

brute_force_matcher_v1_00_a::~brute_force_matcher_v1_00_a(void)
{

}

void brute_force_matcher_v1_00_a::Reset()
{
	get_soc_it_adapter()->Reset(m_DeviceAddress);
	m_IsConfigured = false;
}

string brute_force_matcher_v1_00_a::GetName()
{
	return m_Name;
}

void brute_force_matcher_v1_00_a::set_soc_it_adapter(SocItAdapter* adapter)
{
	m_SocItAdapter = adapter;
}

SocItAdapter* brute_force_matcher_v1_00_a::get_soc_it_adapter()
{
	return m_SocItAdapter;
}

void brute_force_matcher_v1_00_a::SetDeviceAddress(uint8_t bus_id, uint8_t switch_id, uint8_t port_id)
{
	m_DeviceAddress.set_bus_id(bus_id);
	m_DeviceAddress.set_switch_id(switch_id);
	m_DeviceAddress.set_port_id(port_id);
}


SocItAddress brute_force_matcher_v1_00_a::GetDeviceAddress()
{
	return m_DeviceAddress;
}


void brute_force_matcher_v1_00_a::Process(uint64_t modelData_addr, uint64_t modelData_length, uint64_t cellData_addr, uint64_t cellData_length, SocItHandle **matchTable, SocItHandle **matchTableInfo, int numCellsX, int numCellsY, bool wr_matchTbale_info)
{
	if (!m_IsConfigured) {
		return;
	}

	SocItMessage* ProcessMessage;
	SocItMessage* CompleteMessage;
	uint64_t num_model_kp_process;
	uint64_t _modelData_length;
	int num_obsvd_kp = cellData_length / sizeof(keypoint_t<uint32_t>);
	uint64_t num_obsvd_kp_process;
	uint64_t num_obsvd_kp_process_residual;
	uint64_t *_num_obsvd_kp_process = new uint64_t[NUM_ENGINES];
	int num_model_kp = modelData_length / sizeof(keypoint_t<uint32_t>);
	int num_Iterations = (int)ceil((float)num_model_kp / float(MAX_MODEL_KP));
	int *stride = new int[NUM_ENGINES];

	// Set slave Regs
	SocItHandle *slaveData = get_soc_it_adapter()->AllocateMemoryHandle(16);
	_uint128_t *slaveData_ptr = (_uint128_t*)slaveData->get_offset();
	slaveData_ptr[0].lower = (uint64_t)0;
	if (wr_matchTbale_info) {
		slaveData_ptr[0].lower = 1;
	}
	else {
		slaveData_ptr[0].lower = 0;
	}
	slaveData_ptr[0].upper = (uint64_t)NUM_ENGINES;
	get_soc_it_adapter()->Write((uint8_t*)slaveData->get_offset(), 16, GetDeviceAddress(), 0);

	// make space for match table(s)
	SocItHandle **matchTable_buffer = NULL;
	matchTable_buffer = (SocItHandle**)malloc(sizeof(SocItHandle*) * num_Iterations);
	for (int i = 0; i < num_Iterations; i++) {
		matchTable_buffer[i] = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);
	}

	(*matchTable) = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);
	(*matchTableInfo) = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTableInfoOutput_t) * nextMultiple4(numCellsX * numCellsY));

	SocItHandle *commandData = get_soc_it_adapter()->AllocateMemoryHandle(MESSAGE_LENGTH * sizeof(_uint128_t));
	_uint128_t *commandData_ptr = (_uint128_t*)commandData->get_offset();

	uint64_t _matchTable_addr;

	for (int i = 0; i < NUM_ENGINES; i++) {
		_num_obsvd_kp_process[i] = floor(num_obsvd_kp / NUM_ENGINES);
	}
	num_obsvd_kp_process_residual = num_obsvd_kp - floor(num_obsvd_kp / NUM_ENGINES) * NUM_ENGINES;
	for (int i = 0; num_obsvd_kp_process_residual > 0; i = (i + 1) % NUM_ENGINES) {
		_num_obsvd_kp_process[i]++;
		num_obsvd_kp_process_residual--;
	}

	for (int i = 0, j = 0; i < num_model_kp; i += MAX_MODEL_KP, j++) {
        cout << "[BRUTE FORCE MATCHER]: Iteration " << j << endl;
		_matchTable_addr = matchTable_buffer[j]->get_offset();
		ProcessMessage = new SocItMessage(
			SocItMessageType::EXECUTE_REQUEST,
			NULL,
			GetDeviceAddress(),
			true
		);
		_modelData_length = min((MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>)), modelData_length);
		num_model_kp_process = min(MAX_MODEL_KP, (int)((modelData_length) / sizeof(keypoint_t<uint32_t>)));

		for (int k = 0; k < NUM_ENGINES; k++) {
			num_obsvd_kp_process = _num_obsvd_kp_process[k];
			uint64_t matchTable_length = num_obsvd_kp_process * sizeof(matchTable_t);

			if (k == 0) {
				commandData_ptr[0].lower = modelData_addr;
				commandData_ptr[0].upper = cellData_addr;

				commandData_ptr[1].lower = (*matchTableInfo)->get_offset();
				commandData_ptr[1].upper = (_modelData_length << 32) | (cellData_length);

				commandData_ptr[2].lower = (uint64_t)(numCellsX * numCellsY);
				commandData_ptr[2].upper = ((num_model_kp_process) << 16) | ((cellData_length) / sizeof(keypoint_t<uint32_t>));
			}

			commandData_ptr[(k + 3)].lower = _matchTable_addr;
			commandData_ptr[(k + 3)].upper = (matchTable_length << 32) | num_obsvd_kp_process;

			//FILE *fd;
			//fd = fopen("master_data.txt", "a");
			//uint64_t *dataptr = (uint64_t*)ProcessMessage[i]->GetHeaderBytes();
			//fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//fprintf(fd, "%016llX\t%016llX\n", dataptr + 1, dataptr[1]);
			//dataptr = (uint64_t*)ProcessMessage[i]->GetPayloadBytes();
			//for (int i = 0; i < ProcessMessage[i]->get_length() - 16; i += 8, dataptr += 1) {
			//	fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//}
			//fclose(fd);
			stride[k] = num_obsvd_kp_process;
			_matchTable_addr += (uint64_t)(sizeof(matchTable_t) * num_obsvd_kp_process);
		}

		int temp = commandData->get_size();
		ProcessMessage->AddBytes((uint8_t*)(commandData_ptr), commandData->get_size());
        cout << "[BRUTE FORCE MATCHER]: Iteration " << j << " Send SOC-IT Message" << endl;
		get_soc_it_adapter()->SendSocItMessage(ProcessMessage);
        cout << "[BRUTE FORCE MATCHER]: Iteration " << j << " Wait SOC-IT Message" << endl;
		CompleteMessage = get_soc_it_adapter()->WaitSocItMessage(ProcessMessage->get_transaction_id());
		delete ProcessMessage;
		delete CompleteMessage;

		modelData_length -= (MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>));
		modelData_addr += (uint64_t)(_modelData_length);
	}
	coalesceMatches(num_obsvd_kp, matchTable_buffer, num_Iterations, matchTable, stride);


	free(_num_obsvd_kp_process);
	free(stride);
	m_SocItAdapter->DeallocateMemoryHandle(commandData);
	for (int i = 0; i < num_Iterations; i++) {
		m_SocItAdapter->DeallocateMemoryHandle(matchTable_buffer[i]);
	}
	free(matchTable_buffer);
}


#ifdef USE_OPENCV
void brute_force_matcher_v1_00_a::Process(cv::Mat query, cv::Mat train, std::vector<std::vector<cv::DMatch>> &matches, SocItHandle **matchTableInfo, int numCellsX, int numCellsY, bool wr_matchTbale_info)
{
	if (!m_IsConfigured) {
		return;
	}

	int *stride = new int[NUM_ENGINES];


	SocItHandle *modelData;
	dataTransform(train, &modelData);
	SocItHandle *cellData;
	dataTransform(query, &cellData);


	uint64_t modelData_length = modelData->get_size();
	uint64_t modelData_addr = modelData->get_offset();
	uint64_t cellData_length = cellData->get_size();
	uint64_t cellData_addr = cellData->get_offset();


	// Set slave Regs
	SocItHandle *slaveData = get_soc_it_adapter()->AllocateMemoryHandle(16);
	_uint128_t *slaveData_ptr = (_uint128_t*)slaveData->get_offset();
	if (wr_matchTbale_info) {
		(*matchTableInfo) = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTableInfoOutput_t) * nextMultiple4(numCellsX * numCellsY));
		slaveData_ptr[0].lower = 1;
	}
	else {
		slaveData_ptr[0].lower = 0;
	}
	slaveData_ptr[0].upper = 0;
	get_soc_it_adapter()->Write((uint8_t*)slaveData->get_offset(), 16, GetDeviceAddress(), 0);


	SocItMessage* ProcessMessage;
	SocItMessage* CompleteMessage;
	uint64_t num_model_kp_process;
	uint64_t _modelData_length;
	uint64_t _cellData_addr;
	uint64_t _cellData_length;
	uint64_t num_obsvd_kp_process;
	int num_obsvd_kp = cellData_length / sizeof(keypoint_t<uint32_t>);
	uint64_t _num_obsvd_kp_process = num_obsvd_kp / NUM_ENGINES;
	int num_model_kp = modelData_length / sizeof(keypoint_t<uint32_t>);
	int num_Iterations = (int)ceil((float)num_model_kp / float(MAX_MODEL_KP));


	SocItHandle **matchTable_buffer = NULL;
	matchTable_buffer = (SocItHandle**)malloc(sizeof(SocItHandle*) * num_Iterations);
	for (int i = 0; i < num_Iterations; i++) {
		matchTable_buffer[i] = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);
	}
	SocItHandle *matchTable = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);


	SocItHandle *commandData = get_soc_it_adapter()->AllocateMemoryHandle(MESSAGE_LENGTH * sizeof(_uint128_t));
	_uint128_t *commandData_ptr = (_uint128_t*)commandData->get_offset();


	uint64_t _matchTable_addr;
	for (int i = 0, j = 0; i < num_model_kp; i += MAX_MODEL_KP, j++) {
		_matchTable_addr = matchTable_buffer[j]->get_offset();
		for (int k = 0; k < NUM_ENGINES; k++) {
			ProcessMessage = new SocItMessage(
				SocItMessageType::EXECUTE_REQUEST,
				NULL,
				GetDeviceAddress(),
				true
			);

			_modelData_length = min((MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>)), modelData_length);
			num_model_kp_process = min(MAX_MODEL_KP, (int)((modelData_length) / sizeof(keypoint_t<uint32_t>)));
			num_obsvd_kp_process = (i == (NUM_ENGINES - 1)) ? (num_obsvd_kp % ((NUM_ENGINES - 1) * _num_obsvd_kp_process)) : _num_obsvd_kp_process;
			_cellData_length = num_obsvd_kp_process * sizeof(keypoint_t<uint32_t>);

			if (k == 0) {
				commandData_ptr[0].lower = modelData_addr;
				commandData_ptr[0].upper = cellData_addr;

				commandData_ptr[1].lower = (*matchTableInfo)->get_offset();
				commandData_ptr[1].upper = (_modelData_length << 32) | (cellData_length);

				commandData_ptr[2].lower = matchTable_buffer[j]->get_offset();
				commandData_ptr[2].upper = ((num_model_kp_process) << 16) | ((cellData_length) / sizeof(keypoint_t<uint32_t>));
			}
			else {
				commandData_ptr[(k + 2)].lower = _cellData_addr;
				commandData_ptr[(k + 2)].upper = _cellData_length;
				commandData_ptr[(k + 2) + 1].lower = _matchTable_addr;
				commandData_ptr[(k + 2) + 1].upper = (i == (NUM_ENGINES - 1)) ? (num_obsvd_kp % ((NUM_ENGINES - 1) * num_obsvd_kp_process)) : num_obsvd_kp_process;
			}

			//FILE *fd;
			//fd = fopen("master_data.txt", "a");
			//uint64_t *dataptr = (uint64_t*)ProcessMessage[i]->GetHeaderBytes();
			//fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//fprintf(fd, "%016llX\t%016llX\n", dataptr + 1, dataptr[1]);
			//dataptr = (uint64_t*)ProcessMessage[i]->GetPayloadBytes();
			//for (int i = 0; i < ProcessMessage[i]->get_length() - 16; i += 8, dataptr += 1) {
			//	fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//}
			//fclose(fd);

		}

		_cellData_addr += (uint64_t)_cellData_length;
		_matchTable_addr += (uint64_t)(sizeof(matchTable_t) * num_obsvd_kp_process);
		modelData_length -= (MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>));
		modelData_addr += (uint64_t)(_modelData_length);
	}


	coalesceMatches(num_obsvd_kp, matchTable_buffer, num_Iterations, &matchTable, stride);
	dataTransform(matchTable, num_obsvd_kp, matches);


	// clean up
	m_SocItAdapter->DeallocateMemoryHandle(cellData);
	m_SocItAdapter->DeallocateMemoryHandle(modelData);
	m_SocItAdapter->DeallocateMemoryHandle(matchTable);
	for (int i = 0; i < num_Iterations; i++) {
		m_SocItAdapter->DeallocateMemoryHandle(matchTable_buffer[i]);
	}
	free(matchTable_buffer);
	m_SocItAdapter->DeallocateMemoryHandle(commandData);
	if (wr_matchTbale_info) {
		m_SocItAdapter->DeallocateMemoryHandle((*matchTableInfo));
	}
	free(stride);
}

void brute_force_matcher_v1_00_a::Process(std::vector<float> query, std::vector<float> train, std::vector<std::vector<cv::DMatch>> &matches, SocItHandle **matchTableInfo, int numCellsX, int numCellsY, bool wr_matchTbale_info)
{
	if (!m_IsConfigured) {
		return;
	}
	int *stride = new int[NUM_ENGINES];

	SocItHandle *modelData;
	dataTransform(train, &modelData);
	SocItHandle *cellData;
	dataTransform(query, &cellData);


	uint64_t modelData_length = modelData->get_size();
	uint64_t modelData_addr = modelData->get_offset();
	uint64_t cellData_length = cellData->get_size();
	uint64_t cellData_addr = cellData->get_offset();

	// Set slave Regs
	SocItHandle *slaveData = get_soc_it_adapter()->AllocateMemoryHandle(16);
	_uint128_t *slaveData_ptr = (_uint128_t*)slaveData->get_offset();
	if (wr_matchTbale_info) {
		(*matchTableInfo) = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTableInfoOutput_t) * nextMultiple4(numCellsX * numCellsY));
		slaveData_ptr[0].lower = 1;
	}
	else {
		slaveData_ptr[0].lower = 0;
	}
	slaveData_ptr[0].upper = 0;
	get_soc_it_adapter()->Write((uint8_t*)slaveData->get_offset(), 16, GetDeviceAddress(), 0);

	SocItMessage* ProcessMessage;
	SocItMessage* CompleteMessage;
	uint64_t num_model_kp_process;
	uint64_t _modelData_length;
	uint64_t _cellData_addr;
	uint64_t _cellData_length;
	uint64_t num_obsvd_kp_process;
	int num_obsvd_kp = cellData_length / sizeof(keypoint_t<uint32_t>);
	uint64_t _num_obsvd_kp_process = num_obsvd_kp / NUM_ENGINES;
	int num_model_kp = modelData_length / sizeof(keypoint_t<uint32_t>);
	int num_Iterations = (int)ceil((float)num_model_kp / float(MAX_MODEL_KP));

	SocItHandle **matchTable_buffer = NULL;
	matchTable_buffer = (SocItHandle**)malloc(sizeof(SocItHandle*) * num_Iterations);
	for (int i = 0; i < num_Iterations; i++) {
		matchTable_buffer[i] = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);
	}
	SocItHandle *matchTable = m_SocItAdapter->AllocateMemoryHandle(sizeof(matchTable_t) * num_obsvd_kp);

	SocItHandle *commandData = get_soc_it_adapter()->AllocateMemoryHandle(MESSAGE_LENGTH * sizeof(_uint128_t));
	_uint128_t *commandData_ptr = (_uint128_t*)commandData->get_offset();

	uint64_t _matchTable_addr;
	for (int i = 0, j = 0; i < num_model_kp; i += MAX_MODEL_KP, j++) {
		_matchTable_addr = matchTable_buffer[j]->get_offset();
		for (int k = 0; k < NUM_ENGINES; k++) {
			ProcessMessage = new SocItMessage(
				SocItMessageType::EXECUTE_REQUEST,
				NULL,
				GetDeviceAddress(),
				true
			);

			_modelData_length = min((MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>)), modelData_length);
			num_model_kp_process = min(MAX_MODEL_KP, (int)((modelData_length) / sizeof(keypoint_t<uint32_t>)));
			num_obsvd_kp_process = (i == (NUM_ENGINES - 1)) ? (num_obsvd_kp % ((NUM_ENGINES - 1) * _num_obsvd_kp_process)) : _num_obsvd_kp_process;
			_cellData_length = num_obsvd_kp_process * sizeof(keypoint_t<uint32_t>);

			if (k == 0) {
				commandData_ptr[0].lower = modelData_addr;
				commandData_ptr[0].upper = cellData_addr;

				commandData_ptr[1].lower = (*matchTableInfo)->get_offset();
				commandData_ptr[1].upper = (_modelData_length << 32) | (cellData_length);

				commandData_ptr[2].lower = matchTable_buffer[j]->get_offset();
				commandData_ptr[2].upper = ((num_model_kp_process) << 16) | ((cellData_length) / sizeof(keypoint_t<uint32_t>));
			}
			else {
				commandData_ptr[(k + 2)].lower = _cellData_addr;
				commandData_ptr[(k + 2)].upper = _cellData_length;
				commandData_ptr[(k + 2) + 1].lower = _matchTable_addr;
				commandData_ptr[(k + 2) + 1].upper = (i == (NUM_ENGINES - 1)) ? (num_obsvd_kp % ((NUM_ENGINES - 1) * num_obsvd_kp_process)) : num_obsvd_kp_process;
			}

			//FILE *fd;
			//fd = fopen("master_data.txt", "a");
			//uint64_t *dataptr = (uint64_t*)ProcessMessage[i]->GetHeaderBytes();
			//fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//fprintf(fd, "%016llX\t%016llX\n", dataptr + 1, dataptr[1]);
			//dataptr = (uint64_t*)ProcessMessage[i]->GetPayloadBytes();
			//for (int i = 0; i < ProcessMessage[i]->get_length() - 16; i += 8, dataptr += 1) {
			//	fprintf(fd, "%016llX\t%016llX\n", dataptr, dataptr[0]);
			//}
			//fclose(fd);

		}

		_cellData_addr += (uint64_t)_cellData_length;
		_matchTable_addr += (uint64_t)(sizeof(matchTable_t) * num_obsvd_kp_process);
		modelData_length -= (MAX_MODEL_KP * sizeof(keypoint_t<uint32_t>));
		modelData_addr += (uint64_t)(_modelData_length);
	}

	coalesceMatches(num_obsvd_kp, matchTable_buffer, num_Iterations, &matchTable, stride);
	dataTransform(matchTable, num_obsvd_kp, matches);

	// clean up
	m_SocItAdapter->DeallocateMemoryHandle(cellData);
	m_SocItAdapter->DeallocateMemoryHandle(modelData);
	m_SocItAdapter->DeallocateMemoryHandle(matchTable);
	for (int i = 0; i < num_Iterations; i++) {
		m_SocItAdapter->DeallocateMemoryHandle(matchTable_buffer[i]);
	}
	free(matchTable_buffer);
	m_SocItAdapter->DeallocateMemoryHandle(commandData);
	if (wr_matchTbale_info) {
		m_SocItAdapter->DeallocateMemoryHandle((*matchTableInfo));
	}
	free(stride);
}


void brute_force_matcher_v1_00_a::dataTransform(cv::Mat descriptor_in, SocItHandle **kp_desc_out) {

	(*kp_desc_out) = get_soc_it_adapter()->AllocateMemoryHandle(sizeof(keypoint_t<uint32_t>) * descriptor_in.rows);
	keypoint_t<uint32_t> *kp_desc_ptr = (keypoint_t<uint32_t>*)(*kp_desc_out)->get_offset();

	for (int i = 0; i < descriptor_in.rows; i++) {
		for (int j = 0; j < DESC_SIZE; j++) {
			float desc = descriptor_in.at<float>(i, j);
			uint32_t desc_fp = (uint32_t)ceil((float)(desc * pow(2, NUM_FRAC_BITS)));
			kp_desc_ptr[i].descriptors[j] = desc_fp;
			kp_desc_ptr[i].cell_id = 0;
		}
	}
}


void brute_force_matcher_v1_00_a::dataTransform(std::vector<float> descriptor_in, SocItHandle **kp_desc_out) {

	(*kp_desc_out) = get_soc_it_adapter()->AllocateMemoryHandle(sizeof(keypoint_t<uint32_t>) * (descriptor_in.size() / DESC_SIZE));
	keypoint_t<uint32_t> *kp_desc_ptr = (keypoint_t<uint32_t>*)(*kp_desc_out)->get_offset();

	for (int i = 0; i < (descriptor_in.size() / DESC_SIZE); i++) {
		for (int j = 0; j < DESC_SIZE; j++) {
			float desc = descriptor_in[i * DESC_SIZE + j];
			uint32_t desc_fp = (uint32_t)ceil((float)(desc * pow(2, NUM_FRAC_BITS)));
			kp_desc_ptr[i].descriptors[j] = desc_fp;
			kp_desc_ptr[i].cell_id = 0;
		}
	}
}


void brute_force_matcher_v1_00_a::dataTransform(SocItHandle *matches_in, int num_matches_in, std::vector<std::vector<cv::DMatch>> &matches_out) {

	matchTable_t *matches_in_ptr = (matchTable_t*)matches_in->get_offset();

	for (int i = 0; i < num_matches_in; i++) {
		cv::DMatch bestMatch;
		bestMatch.queryIdx = matches_in_ptr[i].first_query_id;
		bestMatch.trainIdx = matches_in_ptr[i].first_model_id;
		bestMatch.distance = matches_in_ptr[i].first_score;
		cv::DMatch secBestMatch;
		secBestMatch.queryIdx = matches_in_ptr[i].second_query_id;
		secBestMatch.trainIdx = matches_in_ptr[i].second_model_id;
		secBestMatch.distance = matches_in_ptr[i].second_score;
		std::vector<cv::DMatch> match_pair;
		match_pair.push_back(bestMatch);
		match_pair.push_back(secBestMatch);
		matches_out.push_back(match_pair);
	}
}
#endif


void brute_force_matcher_v1_00_a::coalesceMatches(int numMatches, SocItHandle **matchTable_in, int numIterations, SocItHandle **matchTable_out, int *stride) {

	matchTable_t *matchTable_out_ptr_tmp = (matchTable_t*)malloc(sizeof(matchTable_t) * numMatches);

	for (int i = 0; i < numMatches; i++) {
		matchTable_out_ptr_tmp[i].first_score = FLT_MAX;
		matchTable_out_ptr_tmp[i].second_score = FLT_MAX;
	}

	// coalese best model keypoint match per obvsd keypoint across iterations
	const size_t nthreads = numIterations;
	std::vector<std::thread> threads(nthreads);
	for (int t = 0; t < nthreads; t++) {
		threads[t] = std::thread(std::bind(
			[&](const int bi, const int ei, const int t) {
			for (int i = 0, offset = 0; i < numIterations; i++, offset += MAX_MODEL_KP) {
				matchTable_t *matchTable_in_ptr = (matchTable_t*)matchTable_in[i]->get_offset();
				for (int j = bi; j < ei; j++) {
					float dist = matchTable_in_ptr[j].first_score;
					uint64_t idx = matchTable_in_ptr[j].first_model_id + offset;
					if (dist < matchTable_out_ptr_tmp[j].first_score) {
						matchTable_out_ptr_tmp[j].second_score = matchTable_out_ptr_tmp[j].first_score;
						matchTable_out_ptr_tmp[j].second_model_id = matchTable_out_ptr_tmp[j].first_model_id;
						matchTable_out_ptr_tmp[j].first_score = dist;
						matchTable_out_ptr_tmp[j].first_model_id = idx;
					} else if (dist < matchTable_out_ptr_tmp[j].second_score) {
						matchTable_out_ptr_tmp[j].second_score = dist;
						matchTable_out_ptr_tmp[j].second_model_id = idx;
					}
					dist = matchTable_in_ptr[j].second_score;
					idx = matchTable_in_ptr[j].second_model_id + offset;
					if (dist < matchTable_out_ptr_tmp[j].first_score) {
						matchTable_out_ptr_tmp[j].second_score = matchTable_out_ptr_tmp[j].first_score;
						matchTable_out_ptr_tmp[j].second_model_id = matchTable_out_ptr_tmp[j].first_model_id;
						matchTable_out_ptr_tmp[j].first_score = dist;
						matchTable_out_ptr_tmp[j].first_model_id = idx;
					} else if (dist < matchTable_out_ptr_tmp[j].second_score) {
						matchTable_out_ptr_tmp[j].second_score = dist;
						matchTable_out_ptr_tmp[j].second_model_id = idx;
					}
				}
			}
		}, t * (numMatches / nthreads), (t + 1) == nthreads ? numMatches : (t + 1) * (numMatches / nthreads), t));
	}
	std::for_each(threads.begin(), threads.end(), [](std::thread& x) {x.join(); });

	// put matches back in order
	matchTable_t *matchTable_out_ptr = (matchTable_t*)(*matchTable_out)->get_offset();
	for (int i = 0, a = 0; i < (int)ceil(((float)numMatches / (float)NUM_ENGINES)); i++) {
		for (int j = 0, k = i; ((j < NUM_ENGINES) && (a < numMatches)); j++, k += stride[j - 1], a++) {
			matchTable_out_ptr[a].first_model_id	=	matchTable_out_ptr_tmp[k].first_model_id;
			matchTable_out_ptr[a].first_score		=	matchTable_out_ptr_tmp[k].first_score;
			matchTable_out_ptr[a].second_model_id	=	matchTable_out_ptr_tmp[k].second_model_id;
			matchTable_out_ptr[a].second_score		=	matchTable_out_ptr_tmp[k].second_score;
		}
	}
	for (int i = 0; i < numMatches; i++) {
		matchTable_out_ptr[i].first_query_id = i;
		matchTable_out_ptr[i].second_query_id = i;
	}
}

