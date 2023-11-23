# 2023-11-09--KubeConNa23_Chicago-Where_s_your_Money_going

<!--
Recording:
https://www.accelevents.com/e/kubecon-cloudnativecon-north-america-2023/portal/schedule/311573
-->

## Links

* [Conference talk](https://kccncna2023.sched.com/event/1R2vE)
* [Slides](https://static.sched.com/hosted_files/kccncna2023/91/Where%27s%20your%20money%20going%20KubeconNA23-1.pdf)
* [Slides (local PDF)](./2023-11-09--KubeConNa23_Chicago-Where_s_your_Money_going.pdf)
* Video TBD

## Extras and stuff

[PromQL fun](https://gist.github.com/jjo/080ae9f49175279f52d744325b0eb482)
used to create some of the visualizations shown in the slides:

* Mock compute spending (`cpu`, `memory`) using a sine wave and adding
  respective values and labels via `label_replace()` and `vector()`

```sql
round(
    8  # <- number of nodes
    *
    (1-sin(vector((time()-(${__to:date:seconds}))/(3600*10) * pi()))) / 2
)
* on() group_right() (
    label_replace(vector(0.0445000) , "spend", "cpu", "", "") * 8  # <- vCPU per node
    or
    label_replace(vector(0.0049225) , "spend", "mem", "", "") * 16 # <- GB per node
)
* on() group_left(unit) (
    label_replace(vector(1) , "unit", "usd_per_hour", "", "")
)
```

![image](https://user-images.githubusercontent.com/88727/285245989-3d543008-2ef7-4580-acaa-b2389e7bc1d6.png)

* Mock compute spending (`cpu`, `memory`) using a sine wave and adding
  respective values and labels via `absent()`

```sql
round(
    8  # <- number of nodes
    *
    (1-sin(vector((time()-(${__to:date:seconds}))/(3600*10) * pi()))) / 2
)
* on() group_right() (
    absent(_x_{spend="cpu"}) * 0.0445000 * 8  # <- vCPU per node
    or
    absent(_x_{spend="memory"}) * 0.0049225 * 16  # <- GB per node
)
* on() group_left(unit) (
    absent(_x_{unit="usd_per_hour"})
)
```

![image](https://user-images.githubusercontent.com/88727/285287928-16a7ff41-2400-4fb3-aae0-683efae9982d.png)
