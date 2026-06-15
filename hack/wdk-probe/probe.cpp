// WDK7 / msvcrt.dll C++ runtime probe.
// Exercises the runtime surfaces that worry us for a full Qt build:
// C++ exceptions, STL containers/strings, and operator new/delete.

#include <string>
#include <vector>
#include <stdexcept>
#include <cstdio>

static int sum_vector(const std::vector<int>& values)
{
    int total = 0;

    for (size_t i = 0; i < values.size(); ++i)
    {
        total += values[i];
    }

    return total;
}

int main()
{
    // 1. STL + heap (operator new/delete inside std::vector / std::string)
    std::vector<int> values;
    values.push_back(10);
    values.push_back(20);
    values.push_back(12);

    std::string label = "wdk-probe";

    // 2. C++ exception throw / catch (needs the EH runtime)
    int caught = 0;
    try
    {
        throw std::runtime_error("boom");
    }
    catch (const std::exception& ex)
    {
        caught = 1;
        printf("caught: %s\n", ex.what());
    }

    // 3. explicit new/delete
    int* heap = new int(99);
    int heapValue = *heap;
    delete heap;

    printf("label=%s sum=%d caught=%d heap=%d\n",
        label.c_str(), sum_vector(values), caught, heapValue);

    return 0;
}
